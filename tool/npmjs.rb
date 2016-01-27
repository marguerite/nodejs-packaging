# get all dependencies for a module
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
				unless link.text == nil
					thread = Thread.new{recursive("https://www.npmjs.com/package/" + link.text)}
					@@threads << thread
				end
			end
		end
	end

	def get(url=@url)

		recursive(url)	

		@@threads.each {|t| t.join}

		if @@deps.size > 1
			return @@deps.uniq! 
		else
			return @@deps
		end

	end

end

p NPMJS.new("forever").get
