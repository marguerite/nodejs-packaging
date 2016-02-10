module Dependencies

    # takes a module name, write all its dependent modules
    # and downloadable files in pretty json

    require 'json'
    require 'fileutils'
    require_relative '/usr/lib/rpm/nodejs/semver.rb'
    require_relative '/usr/lib/rpm/nodejs/vcmp.rb'
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

    def self.skiploop(name='',version='',parents=[])
	if parents.to_s.index("\"#{name}\"")
		ind = parents.index(name)
		str = ""
		if ind == 0
		    str = "@@dependencies[\"#{parents[0]}\"][\"version\"]"
		else
		    for i in 0..ind do
			if i == 0
				str = "@@dependencies[\"#{parents[i]}\"][\"dependencies\"]"
			elsif i == ind
				str += "[\"#{parents[i]}\"][\"version\"]"
			else
				str += "[\"#{parents[i]}\"][\"dependencies\"]"
			end
		    end
		end
		verold = eval(str)
		if verold == version
			return true
		else
			return false
		end
	else
		return false
	end
    end

    def self.bundled(name='',version='',bundles={})
	unless bundles.empty?
		if bundles.keys.include?(name)
			if bundles[name] == version
				return true
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
    end

    def self.list(name:'',comparator:'',parent:'',bundles:{})

	comparator = "*" if comparator == nil
	comphash = Semver.parse(name,comparator) # {'clone':['>=1.0.2','<1.1.0']}

	# get latest latest version
	all = History.all(name)
	latest = all.last

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

	# if the resolved version does not exist, use the
	# most reasonable version
	unless all.include?(version)
		candidates = []
		vs = version.split(".").delete_if {|v| v == "0"} # usually delete starts from the last
		all.each do |v|
			vs1 = v.split(".")
			if vs.size == 2 # no vs.size == 3, because if that the version exists in all
				if vs1[0] == vs[0] && vs1[1] == vs[1]
					candidates << v
				end
			elsif vs.size == 1
				if vs1[0] == vs[0]
					candidates << v
				end
			end
		end
		version = candidates[-1]	
	end

	# find the dependencies
        str = ""
	open(name,'r:UTF-8') {|f| str = f.read}
	json = JSON.parse(str)["versions"][version]

	if parent.empty?
		@@dependencies[name] = {}
		@@dependencies[name]["version"] = version
	else
		parents = Parent.new(@@dependencies,parent).find
		path = Parent.new(@@dependencies,parent).path(parents)
		if path.class == String
		    unless self.skiploop(name,version,parents) # child can't have parent as dependency
		      if eval(path)["dependencies"] == nil
			eval(path)["dependencies"] = {}
			eval(path)["dependencies"][name] = {}
			eval(path)["dependencies"][name]["version"] = version
		      else
			if eval(path)["dependencies"][name] == nil
				eval(path)["dependencies"][name] = {}
				eval(path)["dependencies"][name]["version"] = version
			end
		      end
		    end
		else
		    path.each do |ph|
		      unless self.skiploop(name,version,parents)
			if eval(ph)["dependencies"] == nil
                          eval(ph)["dependencies"] = {}
                          eval(ph)["dependencies"][name] = {}
                          eval(ph)["dependencies"][name]["version"] = version
			else
			  if eval(ph)["dependencies"][name] == nil
				eval(ph)["dependencies"][name] = {}
				eval(ph)["dependencies"][name]["version"] = version
			  end
			end
		      end
		    end
		end
	end

        @@number += 1
        puts "#{@@number}:#{name}"

	# recursively
	unless json["dependencies"] == nil
	    # don't loop the parent in child & the dependency provided by bundles
	    unless self.skiploop(name,version,parents) || self.bundled(name,version,bundles)
		json["dependencies"].each do |k,v|
			self.list(name:k,comparator:v,parent:name,bundles:bundles)
		end
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

    def self.write(name="",bundles={})

	self.list(name:name,bundles:bundles)

	open(name + '.json','w:UTF-8') do |f|
		f.write JSON.pretty_generate(@@dependencies)
	end

	open(name + '.lst','w:UTF-8') do |f|
		@@filelist.each do |k,v|
			v.each do |i|
				f.write "#{k}-#{i}\n"
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

	# clean tmp files
	@@filelist.keys.each {|k| FileUtils.rm_rf(k) }

    end

end

