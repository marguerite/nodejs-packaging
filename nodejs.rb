#!/usr/bin/env ruby

require 'json'
require 'fileutils'


if File.directory?("/usr/src/packages") & File.writable?("/usr/src/packages")
        topdir = "/usr/src/packages"
else
        topdir = ENV["HOME"] + "/rpmbuild"
end
buildroot = Dir.glob(topdir + "/BUILDROOT/*")[0]
sourcedir = topdir + "/SOURCES"
sitelib = "/usr/lib/node_modules"
#buildroot = "/home/marguerite/Public/nodejs-packaging/buildroot"
#sourcedir = "/home/marguerite/Public/nodejs-packaging/build"

def recursive_mkdir(json={},workspace="")

    json.keys.each do |key|
        version = json[key]["version"]
	dest = workspace + "/" + key + "-" + version
	puts "Creating #{dest}"
	FileUtils.mkdir_p dest
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
        name = tgz.gsub('.tgz','')
        io = IO.popen("tar -xf #{tgz}")
        io.close
        FileUtils.mv sourcedir + "/package",sourcedir + "/" + name
    end
when "--mkdir"
    str = ''
    Dir.glob(sourcedir + "/*.json") do |j|
	open(j,'r:UTF-8') {|f| str = f.read}
    end
    json = JSON.parse(str)
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
        prefix = dir.gsub(name,'')
        if name.index(/[0-9]\.[0-9]/)
                FileUtils.mv dir,prefix + name.gsub(/-[0-9].*$/,'')
        end
	if name.index(/test|example/)
		FileUtils.rm_rf dir
	end
    end
when "--filelist"
    open(sourcedir + "/files.lst","w:UTF-8") do |file|
        Dir.glob(buildroot + "/**/*") do |f|
            if File.directory? f
                file.write "%dir " + f.gsub(buildroot,'') + "\n"
            else
                file.write f.gsub(buildroot,'') + "\n"
            end
        end
    end
end

