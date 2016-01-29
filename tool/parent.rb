module Parent

        @@keys = []

	def self.find(json={}, parent="")

	    unless json == nil
	        unless json.key?(parent)
		    @@keys << json.keys[0]
		    self.find(json.values[0]["dependencies"],parent)
	        else
		    @@keys = [parent]
	        end
	    end

	    return @@keys

	end

	def self.path(json={}, parent="")

	    pa = self.find(json,parent)
	    prefix = ""

	    if pa.size > 1
		pa.each do |i|
		    if prefix.empty?
			prefix = "@@dependencies[\"#{i}\"][\"dependencies\"]"
		    else
			prefix += "[\"#{i}\"][\"dependencies\"]"
		    end
		end
	    else
	        prefix = "@@dependencies"
	    end

	    path = prefix + "[\"#{parent}\"]"

	    return path

	end

end

=begin
require 'json'
str = ""
open("test.json") {|f| str = f.read }
json = JSON.parse(str)
parent = "adm-zip"
path = Parent.path(js,parent)
puts eval(path)
=end
