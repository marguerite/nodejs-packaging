#!/usr/bin/env ruby

require 'json'
require 'open-uri'
require 'nokogiri'
require 'net/http'

class Module

	def initialize(name="")
		@name = name
		@url = "https://www.npmjs.com/package/" + @name
	end

	def get_version(url=@url)
		html = Nokogiri::HTML(open(url))
		@version = html.css("ul.box")[0].css("li")[1].css("strong").text
		puts @version
	end

	def download(name=@name,version=@version)


	end

end

Module.new("once").get_version
