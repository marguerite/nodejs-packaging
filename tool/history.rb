# return a module's version history
# return a module's last version
module History

	require_relative 'download.rb'
        require_relative '../nodejs/vcmp.rb'
	include Download
	include Vcmp
	require 'json'

	def self.all(name="")

		url = "http://registry.npmjs.org/" + name
		str = ""
		file = Download.get(url)

		if File.exists?(file)
			File.open(file,'r:UTF-8') {|f| str = f.read}
		end

		json = JSON.parse(str)

		histhash = json["time"].reject! {|k,v| k == "modified" || k == "created"}

		history = []
		histhash.keys.each {|k| history << k}

		return history

	end

	def self.last(name="",version="")

		history = self.all(name)

		if history.include? version
			last = history[history.find_index(version) - 1]
		else
		# history = ["0.6.2","1.0.0"], version = 0.7.0, condition: <0.7.0 
		# sometimes the version used to judge doesn't exist in the history.
		# because eg, author jump from 0.6.2 to 1.0.0 suddenly
			a = history.select do |v|
				if v.index(/beta|alpha|rc|ga/)
					Vcmp.comp(v.gsub(/-.*$/,''),'>',version)
				else
					Vcmp.comp(v,'>',version)
				end
			    end
			if a.empty?
				last = history[-1]
			else
				last = history[history.find_index(a[0]) - 1]
			end
		end

		return last

	end

end

