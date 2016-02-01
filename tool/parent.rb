class Parent

	def initialize(json={},parent="")
            @json = json
            @parent = parent
            @keys,@arrkeys,@temp = [],[],[]
            @i = 0
	end

	
	def find_single(json={},parent="")

            unless json.key?(parent)
                if json.keys.size == 1
                    @keys << json.keys[0]
                    find(json.values[0]["dependencies"],parent)
                else
                    json.keys.each do |k|
                        unless json[k]["dependencies"] == nil
                            if json[k]["dependencies"].to_s.index('"' + parent + '"')
                                @keys << k
                                self.find(json[k]["dependencies"],parent)
                            end
                        end
                    end
                end
            else
                @keys << parent
            end
            return @keys

	end

	def find(json=@json,parent=@parent)
            unless json == nil
                
                count = json.to_s.scan(parent).count
                if count > 1

                    if json.keys.size == 1
                        @temp << json.keys[0]
                        find(json.values[0]["dependencies"],parent)
                    else
                        json.each do |k,v|
                            key = []
                            @temp.each {|j| key << j}
                            key << k
                                    
                            unless k == parent
                                if v["dependencies"].to_s.scan(parent).count == 1
                                    find_single(v["dependencies"],parent)
                                    @keys.each {|k| key << k}
                                    @keys = []
                                    @arrkeys[@i] = []
                                    key.each {|k| @arrkeys[@i] << k}
                                    @i += 1
                                else
                                    @temp << k
                                    find(v["dependencies"],parent)
                                end
                            else
                                @arrkeys[@i] = []
                                key.each {|k| @arrkeys[@i] << k}
                                @i += 1
                                @temp = [@temp[0]] # usually here
                            end
                                    
                        end
                    end
                                
                    return @arrkeys

                else
                    find_single(json,parent)
                    return @keys
                end

            end
	end

	def path(json=@json, parent=@parent)

	    pa = find(json,parent)
            p pa
	    if pa[0].class == String
                path = ""
                if pa.size > 1
                    pa.each do |i|
                        if path == ""
                            path = "@@dependencies[\"#{i}\"]"
			else
                            path += "[\"dependencies\"][\"#{i}\"]"
			end
                    end	
                else
                    path = "@@dependencies[\"#{pa[0]}\"]"
                end
            else
                path = []
                pa.each do |i|
                    ph = ""
                    if i.size > 1
                        i.each do |j|
                            if ph == ""
				ph = "@@dependencies[\"#{j}\"]"
                            else
				ph += "[\"dependencies\"][\"#{j}\"]"
                            end
                        end	
                    else
                        ph = "@@dependencies[\"#{i[0]}\"]"
                    end
                    path << ph
                end
            end

	    return path

	end
        
end

=begin
require 'json'
str = ""
File.open('test.json','r:UTF-8') {|f| str = f.read.gsub('=>',':')}
json = JSON.parse(str)
parent = "pinkie-promise"
p Parent.new(json,parent).find
=end
