module Bundles

	require 'rubygems'
	require 'json'

	if File.directory?("/usr/src/packages") & File.writable?("/usr/src/packages")
        	topdir = "/usr/src/packages"
	else
        	topdir = ENV["HOME"] + "/rpmbuild"
	end
	@@buildroot = Dir.glob(topdir + "/BUILDROOT/*")[0]
	@@sourcedir = topdir + "/SOURCES"
	@@sitelib = "/usr/lib/node_modules"

	def getbuildroot
		return @@buildroot
	end

	def getsourcedir
		return @@sourcedir
	end

	def getsitelib
		return @@sitelib
	end

	def findreq

		req = {}
		spec = Dir.glob("./*.spec")[0]
		open(spec) do |f|
			f.each_line do |l|
				if l.index(/^Requires:\tnpm\(/)
					name = l.gsub(/^.*npm\(/,'').gsub(/\).*$/,'').strip!
					version = ""
					if l.index("=") # FIXME: not only '='
						version = l.gsub(/^.*=\s/,'').strip!
					end
					req[name] = version	  	
				end
			end
		end

		return req

	end

	def findpkgjson(req={})
		req = Bundles.findbundlereq if req.empty?
		pkgjson = []
		req.each do |k,v|
			Dir.glob(buildroot + sitelib + "/**/" + k + "/package.json") do |f|
				json = {}
				open(f) {|f1| json = JSON.parse(f1.read)}
				unless v == nil
					if json["version"] == v
						pkgjson << f
					end					
				else
					pkgjson << f
				end
			end
		end
		return pkgjson
	end

	module_function :getbuildroot
	module_function :getsourcedir
	module_function :getsitelib
	module_function :findreq
	module_function :findpkgjson

end

p Bundles.findreq
