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

    @@download,@@dependencies = {},{}
    @@time = 0

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

        @@time += 1
        puts "#{@@time}:#{name}"

	# recursively
	unless json["dependencies"] == nil
		json["dependencies"].each do |k,v|
			self.list(k,v,name)
		end
	end

	# write downloadable files
	if @@download[json["name"]]
		@@download[json["name"]] << json["version"]
	else
		@@download[json["name"]] = [json["version"]]
	end

	@@download.each {|k,v| v = (v.uniq! if v.uniq!)||v}

    end

    def self.write(name="")

	self.list(name)

	open('dependency.json','w:UTF-8') do |f|
		f.write JSON.pretty_generate(@@dependencies)
	end

# {adm-zip:["0.4.7"],wrappy:["1.0.0","1.0.0","1.0.0"]}

	open('todownload.lst','w:UTF-8') do |f|
		@@download.each do |k,v|
			v.each do |i|
				f.write "#{k};#{k}-#{i}\n"
			end
		end
	end

    end

end

Dependencies.write('phantomjs')
