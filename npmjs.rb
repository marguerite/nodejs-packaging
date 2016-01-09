# get dependencies for a module, no dependencies for dependencies
class NPMJS

	require 'open-uri'
	require 'nokogiri'

	def initialize(name="")

		@url = "https://www.npmjs.com/package/" + name

	end

	@@deps = Array.new
	@@threads = Array.new
	
	def recursive(url="")
		html = Nokogiri::HTML(open(url))
		# start from 0
		links = html.css("div.sidebar p.list-of-links")[1].css("a")
		unless links.empty?
			links.each do |link|
				@@deps << link.text
				thread = Thread.new{recursive("https://www.npmjs.com/package/" + link.text)}
				@@threads << thread
			end
		end
	end

	def get(url=@url)

		recursive(url)	

		@@threads.each {|t| t.join}

		return @@deps.uniq!

	end

end

p NPMJS.new("npm").get
