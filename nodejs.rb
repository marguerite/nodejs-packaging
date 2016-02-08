#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative 'nodejs/bundles.rb'
include Bundles

buildroot = Bundles.getbuildroot
sourcedir = Bundles.getsourcedir
sitelib = Bundles.getsitelib

def has_bundle(key="",version="")

    bundles = Bundles.findreq #{"gulp-util"=>"3.0.7}
    if bundles.keys.include?(key)
      if bundles[key] == nil
	return true
      else
	if bundles[key] == version
		return true
	else
		return false
	end
      end
    else
	return false
    end

end

def recursive_mkdir(json={},workspace="")

    json.keys.each do |key|
        version = json[key]["version"]
	dest = workspace + "/" + key + "-" + version
	puts "Creating #{dest}"
	unless has_bundle(key,version)
	  FileUtils.mkdir_p dest
        end
	unless json[key] == nil
		if json[key].keys.include?("dependencies")
			version = json[key]["version"]
			json[key]["dependencies"].each do |k,v|
				i = {}
				i[k] = v
				recursive_mkdir(i,workspace + "/" + key + "-" + version + "/node_modules")
			end
		end
	end
    end

end

case ARGV[0]
when "--prep"
    Dir.glob(sourcedir + "/*.tgz") do |tgz|
        name = tgz.gsub(/^.*\//,'').gsub('.tgz','')
        io = IO.popen("tar --warning=none -xf #{tgz} -C #{sourcedir}")
        io.close
        FileUtils.mv sourcedir + "/package",sourcedir + "/" + name
    end
when "--mkdir"
    json = {}
    Dir.glob(sourcedir + "/*.json") do |j|
	open(j,'r:UTF-8') {|f| json = JSON.parse(f.read)}
    end
    recursive_mkdir(json,buildroot + sitelib)
when "--copy"
    Dir.glob(buildroot + "/**/*") do |dir|
	name = dir.gsub(/^.*\//,'')
	Dir.glob(sourcedir + "/" + name + "/*") do |f|
		FileUtils.cp_r f,dir
	end
    end
    Dir.glob(buildroot + "/**/*").sort{|x| x.size}.each do |dir|
        name = dir.gsub(/^.*\//,'')
	prefix = dir.gsub(buildroot,'').gsub(name,'')
        if name.index(/[0-9]\.[0-9]/)
                FileUtils.mv dir,buildroot + prefix + name.gsub(/-[0-9].*$/,'')
        end
	if name.index(/test|example|benchmark/)
		FileUtils.rm_rf dir
	end
    end
when "--filelist"
    open(sourcedir + "/files.lst","w:UTF-8") do |file|
        Dir.glob(buildroot + "/**/*") do |f|
            if File.directory? f
		unless f == buildroot + "/usr" || f == buildroot + "/usr/lib" || f == buildroot + sitelib
                    file.write "%dir " + f.gsub(buildroot,'') + "\n"
		end
            else
                file.write f.gsub(buildroot,'') + "\n"
            end
        end
    end
end

