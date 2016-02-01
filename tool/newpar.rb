class Parent

	def initialize(json={},parent="")
		@json = json
		@parent = parent
		@keys = []
		@arrkeys = []
	end

	
	def find_single(json={},parent="")

	    unless json == nil
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

	end

	def find(json=@json,parent=@parent)
		unless json == nil
			count = json.to_s.scan(parent).count
			if count > 1
				if json.keys.size == 1
					count.times { @arrkeys << [json.keys[0]]}
                                        find(json.values[0]["dependencies"],parent)
				else
					json = json.select {|k,v| v.to_s.index(parent)}
					i = 0
					json.each do |k,v|
						key = []
						key << k
						if v["dependencies"].to_s.scan(parent).count == 1
							find_single(v["dependencies"],parent)
							@keys.each {|k| key << k}
							@keys = []
							key.each {|k| @arrkeys[i] << k}
							i += 1
						else
							find(v["dependencies"],parent)
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

        #TODO: adapt to new find

	def path(json=@json, parent=@parent)

	    pa = find(json,parent)
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

	    return path

	end
        
end


require 'json'
str = ""
File.open('test.json','r:UTF-8') {|f| str = f.read.gsub('=>',':')}
json = JSON.parse(str)
parent = "pinkie-promise"
p Parent.new(json,parent).find
