# return a module's version history
# return a module's last version
module History

	require_relative 'download.rb'
	include Download
	require 'rubygems'
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

		# history = ["0.6.2","1.0.0"], version = 0.7.0, condition: <0.7.0 
		# sometimes the version used to judge doesn't exist in the history.
		# because eg, author jump from 0.6.2 to 1.0.0 suddenly
		unless history.include? version
			a = history.select {|v| v.to_f - version.to_f > 0}
			last = history[history.find_index(a[0]) -1]
		else
			last = history[history.find_index(version) - 1]
		end

		return last

	end

end

#p History.last("colors","0.7.0")
