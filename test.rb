require 'open-uri'
require 'nokogiri'
url = "https://www.npmjs.com/package/gulp"
version = Nokogiri::HTML(open(url)).css("div.sidebar ul.box")[0].css("li")[1].css("strong").text

p version
