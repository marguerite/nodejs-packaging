module Download

    # takes a module name and return its package.json in json format

    require 'open-uri'
    require 'nokogiri'
    require 'net/http'
    require 'fileutils'
    require 'rubygems'
    require 'json'
    
    def self.get(name='')

        url = "https://www.npmjs.com/package/" + name
        html = Nokogiri::HTML(open(url))
        version = html.css('div.sidebar ul.box li')[1].css('strong').text
        filename = "#{name}-#{version}.tgz"
        jsonname = filename.gsub('.tgz','.json')
        
        unless File.exists?(filename)
            uri = URI("http://registry.npmjs.org")
            http_object = Net::HTTP.new(uri.host, uri.port)
            #http_object.use_ssl = true if uri.scheme == 'https'
            begin
                http_object.start do |http|
                    http.read_timeout = 500
                    http.request_get("/#{name}/-/#{name}-#{version}.tgz") do |response|
                        open(filename, 'w') do |io|
                            response.read_body do |chunk|
                                io.write chunk
                            end
                        end
                    end
                end
            rescue Exception => e
                puts "=> Exception: '#{e}'. Skipping download."
            end
            
        end
        
        if File.exists?(filename)
            io = IO.popen("tar --warning=none -xf #{filename} package/package.json")
	    io.close
            FileUtils.mv("package/package.json", jsonname)
            FileUtils.rm_rf("package")
        end
        
        str = ""
        json = {}
        File.open(jsonname) {|f| str = f.read} if File.exists?(jsonname)
        json = JSON.parse(str)
        FileUtils.rm_rf jsonname

        #p json
        return json
        
    end

end

#Download.get('forever')
