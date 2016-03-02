module Bower

	require 'json'
	require 'fileutils'
	require 'nokogiri'
	require 'open-uri'
#=begin
	require '/usr/share/npkg/download.rb'
	require '/usr/share/npkg/history.rb'
	require '/usr/lib/rpm/nodejs/semver.rb'
	require '/usr/lib/rpm/nodejs/vcmp.rb'
#=end
=begin
	require_relative "../download.rb"
	require_relative "../history.rb"
	require_relative "../../nodejs/semver.rb"
	require_relative "../../nodejs/vcmp.rb"
=end
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

		unless json.nil? || json.empty?
		  json.each do |k,v|
			url,j,version = "",{},""
			file = Download.get("http://bower.herokuapp.com/packages/" + k)
			if File.exist?(file)
				open(file) {|f| j = JSON.parse(f.read)}
				FileUtils.rm_f file
				url = j["url"].gsub("git://","https://").gsub(".git","")
				html = Nokogiri::HTML(open(url + "/tags"))
				versions_pre,versions,matches = [],[],[]
				html.xpath('//span[@class="tag-name"]').each {|f| versions_pre << f.text
}
				# remove the prefix "v" in eg v3.0.0
				versions_pre.each do |v1|
					if v1.index(/^v/)
						versions << v1.gsub("v","")
					else
						versions << v1
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

				versions_pre.each do |v1|
					if v1.index(match)
						match = v1
						break
					end
				end

				url = url + "/archive/" + match + ".tar.gz"

			end
			jsonnew[k] = url
		  end
		end

		return jsonnew

	end

	def install(name="")

		json = lookup(name)

		unless json.nil? || json.empty?
		  json.each do |k,v|
			io = IO.popen("mkdir -p bower_components/#{k}")
			io.close
			io1 = IO.popen("wget #{v}")
			io1.close
			tarball = v.gsub(/^.*\//,'')
			if File.exist? tarball
				FileUtils.mv tarball,"bower_components/#{k}/"
			end
		  end
		end

		if File.exist? "bower_components"
			io = IO.popen("tar -czf bower_components.tar.gz bower_components")
			io.close
			FileUtils.rm_rf "bower_components"
		end

	end

	module_function :dependency,:lookup,:install

end

