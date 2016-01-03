# get dependencies for a module, no dependencies for dependencies
class NPMJS

	require 'open-uri'
	require 'nokogiri'

	# https://www.npmjs.com/package/gulp
	def initialize(name="")

		@url = "https://www.npmjs.com/package/" + name

	end

	def depends(url=@url)
		deps = Array.new
		html = Nokogiri::HTML(open(url))
		# start from 0
		links = html.css("div.sidebar p.list-of-links")[1].css("a")
		links.each { |link| deps << link.text }
		return deps

	end

end

