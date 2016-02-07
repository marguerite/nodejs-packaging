module Bundles

	require 'rubygems'
	require 'json'
	require_relative 'vcmp.rb'
	include VCMP

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
				# Requires:\tnpm(gulp-util) = 3.0.7
				if l.index(/^Requires:\tnpm\(/)
					name = l.gsub(/^.*npm\(/,'').gsub(/\).*$/,'').strip!
					version = ""
					if l.index(/[0-9]\.[0-9]\.[0-9]/)
						version = l.gsub(/^.*\)\s/,'').strip!
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
					# ">= 3.0.7"
					va = v.split("\s")
					if VCMP.comp(json["version"],va[0],va[1])
						pkgjson << f
					end					
				else
					pkgjson << f
				end
			end
		end
		return pkgjson
	end

	def getrequires(pkgjson=[])
		requires = {}
		pkgjson.each do |f|
			json = {}
			open(f) {|f1| json = JSON.parse(f1.read)}
			unless json["dependencies"] == nil || json["dependencies"].empty?
				json["dependencies"].each do |k,v|
				    if requires[k]
					requires[k] << v
				    else
					requires[k] = v
				    end
				end
			end
		end

		requires.each do |k,v|
			requires[k] = ( v.uniq! if v.uniq! ) || v
		end

		return requires

	end

	module_function :getbuildroot
	module_function :getsourcedir
	module_function :getsitelib
	module_function :findreq
	module_function :findpkgjson
	module_function :getrequires

end

