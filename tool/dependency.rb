module Dependency

    # takes a module name, write all its dependent modules
    # and downloadable files in pretty json

    require 'json'
    require 'fileutils'
#=begin
    require '/usr/lib/rpm/nodejs/semver.rb'
    require '/usr/lib/rpm/nodejs/vcmp.rb'
    require '/usr/share/npkg/history.rb'
    require '/usr/share/npkg/download.rb'
    require '/usr/share/npkg/parent.rb'
#=end
=begin
    require_relative '../nodejs/semver.rb'
    require_relative '../nodejs/vcmp.rb'
    require_relative 'history.rb'
    require_relative 'download.rb'
    require_relative 'parent.rb'
=end
    include Semver    
    include Vcmp
    include History
    include Download

    @@filelist,@@dependencies = {},{}
    @@license = []
    @@number = 0
    
    def skip(name='',version='',array=[])
       
	if array.include?(name)
 
        ind = 0
                
        # find from last
        array.to_enum.with_index.reverse_each do |k,i|
            if k == name
                ind = i
                break
            end
        end
                
        str = ""
        if ind == 0
            str = "@@dependencies[\"#{array[0]}\"][\"version\"]"
        else
            for i in 0..ind do
                if i == 0
                    str = "@@dependencies[\"#{array[i]}\"][\"dependencies\"]"
                elsif i == ind
                    str += "[\"#{array[i]}\"][\"version\"]"
                else
                    str += "[\"#{array[i]}\"][\"dependencies\"]"
                end
            end
        end
        verold = eval(str)
        if verold == version
            return 1
        else
            return 0
        end

	else

		return -1
	end
        
    end

    def skiploop(name='',version='',parents=[])
	if ( ! parents.nil? ) && parents.to_s.index("\"#{name}\"")

            if parents[0].class == String
                
                if skip(name,version,parents) > 0
                    return true
                else
                    return false
                end

            else
                arr = []
                parents.each {|pa| arr << skip(name,version,pa)}

                if arr.include?(0)
                    return false
                else
                    return true
                end
                
            end
                
	else
		return false
	end
    end

    def bundled(name='',version='',bundles={})
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

    def list(name:'',comparator:'',parent:'',bundles:{})

	comparator = "*" if comparator.nil?
	comphash = Semver.parse(name,comparator) # {'clone':['>=1.0.2','<1.1.0']}

	# get latest latest version
	all = History.all(name)
	latest = all.last

	# calculate proper version that suits the conditions
	comphash.reject! do |_k,hv|
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
        json = {}
	open(name,'r:UTF-8') {|f| json = JSON.parse(f.read)["versions"][version]}

	if parent.empty?
		@@dependencies[name] = {}
		@@dependencies[name]["version"] = version
	else
		parents = Parent.new(@@dependencies,parent).find
		path = Parent.new(@@dependencies,parent).path(parents)
		if path.class == String
		    unless skiploop(name,version,parents) # child can't have parent as dependency
		      if eval(path)["dependencies"].nil?
			eval(path)["dependencies"] = {}
			eval(path)["dependencies"][name] = {}
			eval(path)["dependencies"][name]["version"] = version
		      else
			if eval(path)["dependencies"][name].nil?
				eval(path)["dependencies"][name] = {}
				eval(path)["dependencies"][name]["version"] = version
			end
		      end
		    end
		else
		    path.each do |ph|
		      unless skiploop(name,version,parents)
			if eval(ph)["dependencies"].nil?
                          eval(ph)["dependencies"] = {}
                          eval(ph)["dependencies"][name] = {}
                          eval(ph)["dependencies"][name]["version"] = version
			else
			  if eval(ph)["dependencies"][name].nil?
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
	unless json["dependencies"].nil?
	    # don't loop the parent in child & the dependency provided by bundles
	    unless skiploop(name,version,parents) || bundled(name,version,bundles)
		json["dependencies"].each do |k,v|
			list(name:k,comparator:v,parent:name,bundles:bundles)
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
        if ! json["license"].nil?
	    if json["license"].class == Hash
		@@license << json["license"]["type"]
	    elsif json["license"].class == Array
		json["license"].each {|h| @@license << h}
	    else
		@@license << json["license"]
	    end
	elsif ! json["licenses"].nil?
	    if json["licenses"].class == Array
		json["licenses"].each do |h|
		    if h.class == String
			@@license << h
		    else
			@@license << h["type"]
		    end
		end
	    else # Hash
		@@license << json["licenses"]["type"]
	    end
        end

	@@filelist.values.each {|v| v = (v.uniq! if v.uniq!)||v}
	@@license = (@@license.uniq! if @@license.uniq!)||@@license

    end

    def write(name="",bundles={})

	list(name:name,bundles:bundles)

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
    
    module_function :skip,:skiploop
    module_function :bundled
    module_function :list
    module_function :write

end

