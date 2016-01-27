# return a module's version history
# return a module's last version
module History

	require_relative 'download.rb'
	include Download
	require 'json'
	require 'fileutils'

	def self.all(name="")

		url = "http://registry.npmjs.org/" + name
		str = ""
		file = Download.get(url)

		if File.exists?(file)
			File.open(file) {|f| str = f.read}
			FileUtils.rm_rf file
		end

		json = JSON.parse(str)

		histhash = json["time"].reject! {|k,v| k == "modified" || k == "created"}

		history = []
		histhash.keys.each {|k| history << k}

		return history

	end

	def self.last(name="",version="")

		history = self.all(name)

		last = history[history.find_index(version) - 1]

		return last

	end

end

#p History.last("clone","1.0.0")
