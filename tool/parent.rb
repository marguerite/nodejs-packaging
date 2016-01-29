module Parent

        @@path = []

	def self.find(json={}, parent="")

	    unless json == nil

	    unless json.key?(parent)
		@@path << json.keys[0]
		self.find(json.values[0]["dependencies"],parent)
	    end

	    end

	    return @@path

	end

	def self.path(json={}, parent="")

	    pa = self.find(json,parent)

	    prefix = ""

	    pa.each do |i|

		if prefix == ""
		    prefix = "#{json}[\"#{i}\"][\"dependencies\"]"
		else
		    prefix += "[\"#{i}\"][\"dependencies\"]"
		end

	    end

	    path = prefix + "[\"#{parent}\"]"

	    return path

	end

end

=begin
require 'json'
str = ""
open("test.json") {|f| str = f.read }
js = JSON.parse(str)
parent = "adm-zip"
path = Parent::path(js,parent)

puts eval(path)
=end
