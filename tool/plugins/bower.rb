module Bower

	require 'json'
	require 'fileutils'
	require 'nokogiri'
	require 'open-uri'
	require_relative "../download.rb"
	require_relative "../history.rb"
	require_relative "../../nodejs/semver.rb"
	require_relative "../../nodejs/vcmp.rb"
	include Semver
	include Vcmp
	include Download
	include History

	def dependency(name="")

		json = {}
		open("package/bower.json") {|f| json = JSON.parse(f.read)}
		return json["dependencies"]

	end

	def lookup(name="")

		json = dependency(name)
		jsonnew = {}

		json.each do |k,v|
			url,j,version = "",{},""
			file = Download.get("http://bower.herokuapp.com/packages/" + k)
			if File.exist?(file)
				open(file) {|f| j = JSON.parse(f.read)}
				FileUtils.rm_f file
				url = j["url"].gsub("git://","https://").gsub(".git","")
				html = Nokogiri::HTML(open(url + "/tags"))
				versions,matches = [],[]
				html.xpath('//span[@class="tag-name"]').each {|f| versions << f.text
}
				# remove the prefix "v" in eg v3.0.0
				versions.map! do |v1|
					if v1.index(/^v/)
						v1.gsub("v","")
					else
						v1
					end
				end

				semver = Semver.parse(k,v)
				versions.each do |i|
				  arr = []
				  semver.values.each do |v1|
				    v1.each do |v2|
					op = v2.gsub(/[0-9].*$/,'')
					ve = v2.gsub(op,'')
					if Vcmp.comp(i,op,ve)
						arr << 1
					else
						arr << 0
					end
				    end
				  end
				  matches << i unless arr.include?(0)
				end

				match = matches[0]
				url = url + "/archives/v" + match + "/" + k + "-" + match + ".tar.gz"

			end
			jsonnew[k] = url
		end

		return jsonnew

	end

	def install(name="")

		json = lookup(name)
		json.each do |k,v|
			io = IO.popen("mkdir -p bower_components/#{k}")
			io.close
			Download.get(v)
			tarball = v.gsub(/^.*\//,'')
			if File.exist? tarball
				FileUtils.mv tarball,"bower_components/#{k}/"
			end
		end

		if File.exist? "bower_components"
			IO.popen("tar -czf bower_components.tar.gz bower_components")
		end

	end

	module_function :dependency,:lookup,:install

end

p Bower.install("tryton-sao")
