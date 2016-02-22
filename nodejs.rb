#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require '/usr/lib/rpm/nodejs/bundles.rb'
require '/usr/lib/rpm/nodejs/vcmp.rb'
include Bundles
include Vcmp

buildroot = Bundles.getbuildroot
sourcedir = Bundles.getsourcedir
sitelib = Bundles.getsitelib

def has_bundle(key="",version="")

    bundles = Bundles.findreq #{"gulp-util"=>"= 3.0.7}
    if bundles.keys.include?(key)
      if bundles[key] == nil
	return true
      else
	va = bundles[key].split(/\s/)
	if Vcmp.comp(version,va[0],va[1])
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
        unless has_bundle(key,version)
	  puts "Creating #{dest}"
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

def backpath(path="",count="")

        count.times do

                path = path.gsub(/\/$/,'')
                path = path.gsub(path.gsub(/^.*\//,''),'')
                unless count == 1
                        backpath(path,count - 1)
                end

        end

        return path

end

def find_symlink(symlink="",target="")

        path = symlink.gsub(symlink.gsub(/^.*\//,''),'')
        count = target.scan("..").count
        back = backpath(path,count)
        suffix = target.gsub(/^.*\.\.\//,'')
        realpath = back + suffix

        return realpath
end

def filter(file="")
    f = file.split("/")
    if f.grep(/^\..*$|.*~$|\.bat|\.cmd|Makefile|test(s)?(\.js)?|example(s)?(\.js)?|benchmark(s)?(\.js)?|\.sh|_test\.|browser$|\.orig|\.bak|windows|\.sln|\.njsproj|\.exe|\.c|\.h|\.cc|\.cpp/).empty?
	if f.grep(/LICENSE|\.md|\.txt|\.markdown/)
		io = IO.popen("chmod -x #{file}")
		io.close
	end
	return file
    else
        return nil
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
    
    # bower
    if File.exist?(sourcedir + "/bower_components.tar.gz")
	io = IO.popen("tar -xf #{sourcedir}/bower_components.tar.gz -C #{sourcedir}")
	io.close

    	Dir.glob(sourcedir + "/bower_components/**/*.tar.gz") do |dir|
		dir1 = dir.gsub(dir.gsub(/^.*\//,''),'')
        	io1 = IO.popen("tar -xf #{dir} -C #{dir1}")
        	io1.close
		FileUtils.rm_rf dir
        	Dir.glob(dir1 + "/*") do |i|
        		io2 = IO.popen("cp -r #{i}/* #{dir1}/")
        		io2.close
			FileUtils.rm_rf i
        	end
	end

    end
    
when "--mkdir"
    json = {}
    
    Dir.glob(sourcedir + "/*.json") do |j|
	open(j,'r:UTF-8') {|f| json = JSON.parse(f.read)}
    end
    
    recursive_mkdir(json,buildroot + sitelib)
    
when "--build"
    buildlist = []
    
    Dir.glob(sourcedir + "/**/*") do |f|
        if f.end_with?(".c") || f.end_with?(".h") || f.end_with?(".cc") || f.end_with?(".cpp")
            name = f.gsub(/^.*node_modules\//,'').gsub(/\/.*$/,'')
            prefix = f.gsub(buildroot,'').gsub(/#{name}\/.*$/,'')
            prefix = buildroot + prefix + name
            buildlist << prefix
        end
    end
    
    buildlist = ( buildlist.uniq! if buildlist.uniq! ) || buildlist
    
    buildlist.each do |b|
        io = IO.popen("pushd #{b} && npm build -f && popd")
        io.close
    end
    # clean middle files
    Dir.glob(sourcedir + "/**/*") do |f|
        FileUtils.rm_rf f if f.index(/build\/(Release|Debug)/)
    end
    # clean empty directories
    Dir[sourcedir + "/**/*"].select{|d| File.directory? d}.select{|d| (Dir.entries(d) - %w[ . .. ]).empty?}.each{|d| Dir.rmdir d}
    
when "--copy"
    Dir.glob(buildroot + "/**/*") do |dir|
        name = dir.gsub(/^.*\//,'')
        Dir.glob(sourcedir + "/" + name + "/*") do |f|
	    file = filter(f)
	    unless file.nil?
		if File.directory? file
			dir1 = file.gsub(/^.*[0-9]\.[0-9]/,'')
			FileUtils.mkdir_p dir + dir1
			Dir.glob(file + "/**/*") do |f1|
				FileUtils.cp_r f1,dir + dir1
			end
		else
	    		FileUtils.cp_r file,dir
		end
	    end
        end
    end
    
    Dir.glob(buildroot + "/**/*").sort{|x| x.size}.each do |dir|
        name = dir.gsub(/^.*\//,'')
	prefix = dir.gsub(buildroot,'').gsub(name,'')
        if name.index(/-[0-9]\.[0-9]/)
                FileUtils.mv dir,buildroot + prefix + name.gsub(/-[0-9].*$/,'')
        end
    end
    
    # bower
    main = Dir.glob(buildroot + sitelib + "/*")[0]
    if Dir.exist?(sourcedir + "/bower_components")
        Dir.glob(sourcedir + "/bower_components/**/*") do |f|
                if File.directory?(f)
                        FileUtils.mkdir_p f.gsub(sourcedir,main)
                end
        end

        Dir.glob(sourcedir + "/bower_components/**/*").sort{|x| x.size}.each do |f|
		if File.symlink?(f)
			real_target = find_symlink(f,File.readlink(f))
			if File.directory? real_target
				FileUtils.mkdir_p real_target.gsub(sourcedir,main)
				Dir.glob(real_target + "/**/*") do |i|
				    name = i.gsub(real_target,'')
				    FileUtils.ln_sf i.gsub(sourcedir,main).gsub(buildroot,''),f.gsub(sourcedir,main) + name
				end
			else
				FileUtils.ln_sf real_target.gsub(sourcedir,main).gsub(buildroot,''),f.gsub(sourcedir,main)
			end
		end
		unless File.directory?(f) || File.symlink?(f) || f.end_with?("package.json") || f.end_with?("bower.json")
                    file = filter(f)
                    unless file.nil?
			f1 = f.gsub(sourcedir + "/bower_components",'')
			dir = f.gsub(f1,'').gsub(sourcedir,main)
			FileUtils.cp_r file,dir + f1
                    end
		end
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

