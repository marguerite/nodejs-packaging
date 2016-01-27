module PKGJSON

    # takes a module name and return its package.json in json format

    require 'open-uri'
    require 'nokogiri'
    require 'fileutils'
    require 'rubygems'
    require 'json'
    require_relative '../nodejs/semver.rb'
    require_relative '../nodejs/vcmp.rb'
    require_relative 'history.rb'
    require_relative 'download.rb'
    include Semver    
    include Vcmp
    include History
    include Download

    def self.get(name='',comparator='')

	comparator = "*" if comparator == nil
	comphash = Semver.parse(name,comparator) # {'clone':['>=1.0.2','<1.1.0']}	
        url = "https://www.npmjs.com/package/" + name
        html = Nokogiri::HTML(open(url))
        upstream = html.css('div.sidebar ul.box li')[1].css('strong').text # '1.0.2'

	# calculate proper version to download
	comphash.reject! do |k,hv|
		hv.reject! do |v|
			op = v.gsub(/[0-9].*$/,'')
			ve = v.gsub(op,'')
			Vcmp.comp(upstream,op,ve)	
		end
		hv.empty?
	end

	if comphash.empty?
		version = upstream
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

	filename = "#{name}-#{version}.tgz"
	jsonname = filename.gsub('.tgz','.json')

        unless File.exists?(filename)
	    url = "https://registry.npmjs.org/" + name + "/-/" + filename
            Download.get(url)
        end

        if File.exists?(filename)
            io = IO.popen("tar --warning=none -xf #{filename} package/package.json")
	    io.close
            FileUtils.mv("package/package.json", jsonname)
            FileUtils.rm_rf "package"
        end
        
        str = ""
        json = {}
        File.open(jsonname) {|f| str = f.read} if File.exists?(jsonname)
        json = JSON.parse(str)

        return json
   
    end

end

#p PKGJSON.get('clone','~1.0.2')
