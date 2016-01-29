module Dependencies

    # takes a module name and return its package.json in json format

    require 'rubygems'
    require 'json'
    require_relative '../nodejs/semver.rb'
    require_relative '../nodejs/vcmp.rb'
    require_relative 'history.rb'
    require_relative 'download.rb'
    require_relative 'parent.rb'
    include Semver    
    include Vcmp
    include History
    include Download
    include Parent

    @@download,@@dependencies = {},{}

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
	File.open(name) {|f| str = f.read}
	json = JSON.parse(str)["versions"][version]

	if parent.empty?
		@@dependencies[name] = {}
		@@dependencies[name]["version"] = version
	else
		ps = Parent.path(@@dependencies,parent)
		eval(ps)["dependencies"] = {}
		eval(ps)["dependencies"][name] = {}
		eval(ps)["dependencies"][name]["version"] = version
	end

	# recursively
	json["dependencies"].each do |k,v|
		self.list(k,v,name)
	end

	p @@dependencies

    end
end
=begin
	# write download files
	if @@download[json["name"]]
		@@download[json["name"]] << json["version"]
	else
		@@download[json["name"]] = [json["version"]]
	end
=end

Dependencies.list('phantomjs')
