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
        
        def get_str(temp=[])
            str = ""
            temp.each do |t|
                if t == temp[0]
                    str = "@json[\"#{t}\"][\"dependencies\"]"
                else
                    str += "[\"#{t}\"][\"dependencies\"]"
                end
            end
            
            return str
        end
        
        def clean_temp(temp=@temp)
            
            newtemp = [temp[-1]]
           
            if temp.size > 1 # temp = 1, most of the times don't need to clean
                last = get_str(temp)
                looptimes = eval(last).select{|k,v| v.to_s.index(@parent) || k == @parent}.keys.size

                if @arrkeys.to_s.scan(@parent).count == looptimes
                    temp.each_index do |i|
                        n = temp.size - i - 1 # 5 - i
                        #["gulp","gulp-utils","dateformat","meow","read-pkg-up","find-up"]
                        str = get_str(temp[0...n])
                        s = eval(str).select{|k,v| k != temp[n+1] && ( v.to_s.index(@parent) || k == @parent)}
                        newtemp << temp[n]
                        if s != nil && s.keys.size >= 1
                            break
                        else
                            next
                        end
                    end    
                end
            end

            return (temp - newtemp)
        end

	def find(json=@json,parent=@parent)
            
            unless json == nil
                
                count = json.to_s.scan("\"#{parent}\"").count
                if count > 1

                    if json.keys.size == 1
                        @temp << json.keys[0]
                        find(json.values[0]["dependencies"],parent)
                    else
                        json.each do |k,v|
                          if k == parent || v.to_s.index("\"#{parent}\"")
                            key = []
                            @temp.each {|j| key << j}
                            key << k
                                    
                            unless k == parent
                                if v["dependencies"].to_s.scan("\"#{parent}\"").count == 1
                                    find_single(v["dependencies"],parent)
                                    @keys.each {|k1| key << k1}
                                    @keys = []
                                    @arrkeys[@i] = []
                                    key.each {|k1| @arrkeys[@i] << k1}
                                    @i += 1
                                else
                                    @temp << k
                                    find(v["dependencies"],parent)
                                end
                            else
                                @arrkeys[@i] = []
                                key.each {|k1| @arrkeys[@i] << k1}
                                @i += 1
                            end
                          end          
                        end
                    end

                    @temp = clean_temp(@temp)
                       
                    return @arrkeys

                else
                    find_single(json,parent)
                    return @keys
                end

            end
	end

	def path(keys=[])
            if keys[0].class == String
                path = ""
                if keys.size > 1
                    keys.each do |i|
                        if path == ""
                            path = "@@dependencies[\"#{i}\"]"
			else
                            path += "[\"dependencies\"][\"#{i}\"]"
                        end
                    end	
                else
                    path = "@@dependencies[\"#{keys[0]}\"]"
                end
            else
                path = []
                keys.each do |i|
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
json = {}
File.open('test.json','r:UTF-8') {|f| json = JSON.parse(f.read)}
parent = "xtend"
p Parent.new(json,parent).find
=end
