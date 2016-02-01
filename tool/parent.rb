class Parent

	def initialize(json={},parent="")
		@json = json
		@parent = parent
		@keys = []
	end


	def find(json=@json, parent=@parent)
            
	    unless json == nil
	        unless json.key?(parent)
			if json.keys.size == 1
				@keys << json.keys[0]
				self.find(json.values[0]["dependencies"],parent)
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