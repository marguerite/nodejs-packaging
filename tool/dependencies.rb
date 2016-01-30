module Dependencies

    # takes a module name, write all its dependent modules
    # and downloadable files in pretty json

    #require 'rubygems'
    require 'json'
    require 'fileutils'
    require_relative '../nodejs/semver.rb'
    require_relative '../nodejs/vcmp.rb'
    require_relative 'history.rb'
    require_relative 'download.rb'
    require_relative 'parent.rb'
    include Semver    
    include Vcmp
    include History
    include Download

    @@filelist,@@dependencies = {},{}
    @@license = []
    @@number = 0

    def self.list(name='',comparator='',parent='')

	comparator = "*" if comparator == nil
	comphash = Semver.parse(name,comparator) # {'clone':['>=1.0.2','<1.1.0']}	

	# get latest latest version
	latest = History.all(name).last

	# calculate proper version that suits the conditions
	comphash.reject! do |k,hv|
		hv.reject! do |v|
			op = v.gsub(/[0-9].*$/,'')
			ve = v.gsub(op,'')
			Vcmp.comp(latest,op,ve)	
		end
		hv.empty?
	end

	if comphash.empty?
		version = latest
        else
		comphash.values.each do |values|
			values.each do |v|
				op = v.gsub(/[0-9].*$/,'')
				ve = v.gsub(op,'')
				# op: '<=' or '<'
				if op == '<'
					version = History.last(name,ve)
				else
					version = ve
				end
			end
		end
	end

	# find the dependencies
        str = ""
	open(name) {|f| str = f.read}
	json = JSON.parse(str)["versions"][version]
	FileUtils.rm_rf name

	if parent.empty?
		@@dependencies[name] = {}
		@@dependencies[name]["version"] = version
	else
		ps = Parent.new(@@dependencies,parent).path
		eval(ps)["dependencies"] = {} if eval(ps)["dependencies"] == nil
		eval(ps)["dependencies"][name] = {}
		eval(ps)["dependencies"][name]["version"] = version
	end

        @@number += 1
        puts "#{@@number}:#{name}"

	# recursively
	unless json["dependencies"] == nil
		json["dependencies"].each do |k,v|
			self.list(k,v,name)
		end
	end

	# write downloadable filelist
	if @@filelist[json["name"]]
		@@filelist[json["name"]] << json["version"]
	else
		@@filelist[json["name"]] = [json["version"]]
	end

	# write licenses
        if json["license"] != nil
	    if json["license"].class == Hash
		@@license << json["license"]["type"]
	    else
		@@license << json["license"]
	    end
	elsif json["licenses"] != nil
		json["licenses"].each do |h|
			@@license << h["type"]
		end
	end

	@@filelist.each {|k,v| v = (v.uniq! if v.uniq!)||v}
	@@license = (@@license.uniq! if @@license.uniq!)||@@license

    end

    def self.write(name="")

	self.list(name)

	open(name + '.json','w:UTF-8') do |f|
		f.write JSON.pretty_generate(@@dependencies)
	end

	open(name + '.lst','w:UTF-8') do |f|
		@@filelist.each do |k,v|
			v.each do |i|
				f.write "#{k};#{k}-#{i}\n"
			end
		end
	end

	open(name + '.license','w:UTF-8') do |f|
		unless @@license.size > 1
			@@license.each {|i| f.write i}
		else
			@@license.each do |i|
				unless i == @@license.last
					f.write i + " and "
				else
					f.write i
				end
			end
		end
	end

    end

end

