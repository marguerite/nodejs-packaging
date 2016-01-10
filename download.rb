# Download all dependencies for a module
module ModuleDownload

	require 'open-uri'
	require 'nokogiri'
	require 'net/http'
	require_relative './npmjs.rb'

	def self.download(modules=[])

		unless modules.empty?

			modules.each do |m|

				url = "https://www.npmjs.com/package/" + m

				version = Nokogiri::HTML(open(url)).css("div.sidebar ul.box")[0].css("li")[1].css("strong").text

				p m
				p url
				p version

				Net::HTTP.start("https://registry.npmjs.org") do |http|
					f = open('#{m}-#{version}.tgz')
					begin
						http.request_get('/#{m}/-/#{m}-#{version}.tgz') do |resp|
							resp.read_body do |segment|
								f.write(segment)
							end
						end
					ensure
						f.close()
					end
				end

			end

		end

	end

end

puts ModuleDownload.download(["wrappy"])
