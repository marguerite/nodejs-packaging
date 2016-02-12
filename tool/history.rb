# return a module's version history
# return a module's last version
module History
#=begin
	require '/usr/share/npkg/download.rb'
        require '/usr/lib/rpm/nodejs/vcmp.rb'
#=end
=begin
	require_relative 'download.rb'
	require_relative '../nodejs/vcmp.rb'
=end
	include Download
	include Vcmp
	require 'json'

	def sort(arr=[],size=0,changed=0)
		# bundle sort
        	i,j = 0,changed
        	size = arr.size if size == 0
        	while i < size - 1 do
                	if Vcmp.comp(arr[i],">",arr[i+1])
                        	m = arr[i]
                        	n = arr[i+1]
                        	arr.map! do |a|
                            		if a == m
                                		n
                            		elsif a == n
                                		m
                            		else
                                		a
                            		end
                        	end
                        	changed += 1
                	end
                	i += 1
        	end

        	unless size == 1 || j == changed
                	sort(arr,size - 1,changed)
        	end

        	return arr

	end

	def all(name="")

		url = "http://registry.npmjs.org/" + name
		file = Download.get(url)
		json,history = {},[]

		if File.exist?(file)
			File.open(file,'r:UTF-8') {|f| json = JSON.parse(f.read)}
		end

		histhash = json["time"].reject! {|k,_v| k == "modified" || k == "created"}
		histhash.keys.each do |k|
			unless json["versions"][k].nil? # "graceful-fs@2.1.0" doesn't exist
				history << k
			end
		end

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

