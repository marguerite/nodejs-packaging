# return a module's version history
# return a module's last version
module History

	require_relative 'download.rb'
        require_relative '/usr/lib/rpm/nodejs/vcmp.rb'
	include Download
	include Vcmp
	require 'json'

	def sort(versions=[])
		va,result = [],[]
		# strip beta versions
		versions.reject! {|v| v.index("-")}
		versions.each do |v|
			a = v.split(".")
			b = [] 
			a.each {|v| b << v.to_i}
			va << b	
		end
		va = va.sort!
		va.each do |v|
			vs = ""
			v.each_with_index do |k,i|
				unless i == v.size - 1
					vs += k.to_s + "."
				else
					vs += k.to_s
				end
			end
			result << vs
		end
		return result
	end

	def all(name="")

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

		return sort(history) # the result is not natively sorted.

	end

	def last(name="",version="")

		history = all(name)

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

	module_function :sort,:all,:last

end

