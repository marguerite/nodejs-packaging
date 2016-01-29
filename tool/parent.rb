module Parent

        @@keys = []

	def self.find(json={}, parent="")

	    unless json == nil

	    unless json.key?(parent)
		@@keys << json.keys[0]
		self.find(json.values[0]["dependencies"],parent)
	    end

	    end

	    return @@keys

	end

	def self.path(json={}, parent="")

	    pa = self.find(json,parent)

	    prefix = ""

	    pa.each do |i|

		if prefix.empty?
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
