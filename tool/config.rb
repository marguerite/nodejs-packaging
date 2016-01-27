module Config

WORKSPACE="/root/nodejs-packaging/tool"

# return config file's path
	def self.get
		logname = ENV['LOGNAME']
		if File.exists? "/home/#{logname}/.config/jspak.conf"
			config = "/home/#{logname}/.config/jspak.conf"
		elsif File.exists? "/etc/nodejs-packaging/jspak.conf"
			config = "/etc/nodejs-packaging/jspak.conf"
		elsif File.exists? "#{WORKSPACE}/config"
			config = WORKSPACE + "/config"
		end # TODO: read stdin and save config

		return config
	end
end

#p Config.get
