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

    json.each do |key,v|
        version = v["version"]
	dest = workspace + "/" + key + "-" + version
        unless has_bundle(key,version)
	  puts "Creating #{dest}"
	  FileUtils.mkdir_p dest
        end
	unless v.nil?
		if v.keys.include?("dependencies")
			v["dependencies"].each do |k,v1|
				i = {}
				i[k] = v1
				recursive_mkdir(i,workspace + "/" + key + "-" + version + "/node_modules")
			end
		end
	end
    end

end

def recursive_copy(path="",dir="")
    file = filter(path)
    unless file.nil?
      if File.directory? file
        dir1 = file.gsub(/^.*\//,'')
	puts "Making directory " + dir + "/" + dir1
        FileUtils.mkdir_p dir + "/" + dir1
        Dir.glob(file + "/*") do |f1|
          f2 = filter(f1)
          unless f2.nil?
            if File.directory? f2
              recursive_copy(f2,dir + "/" + dir1)
	    else
	      puts "Copying " + f2 + " => " + dir + "/" + dir1
              FileUtils.cp_r f2,dir + "/" + dir1
	    end
          end
        end
      else
	puts "Copying " + file + " => " + dir
        FileUtils.cp_r file,dir
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
    if f.grep(/^\..*$|.*~$|\.bat$|\.cmd$|Makefile|test(s)?(\.js)?|example(s)?(\.js)?|benchmark(s)?(\.js)?|sample(s)?(\.js)?|\.sh$|_test\.|browser$|\.orig$|\.bak$|windows|\.sln$|\.njsproj$|\.exe$|appveyor\.yml/).empty?
	return file
    else
        return nil
    end

end

case ARGV[0]
when "--prep"
    Dir.glob(sourcedir + "/*.tgz") do |tgz|
        name = tgz.gsub(/^.*\//,'').gsub('.tgz','')
        io = IO.popen("tar --warning=none --no-same-owner --no-same-permissions -xf #{tgz} -C #{sourcedir}")
        io.close
        FileUtils.mv sourcedir + "/package",sourcedir + "/" + name
    end
    
    # bower
    if File.exist?(sourcedir + "/bower_components.tar.gz")
	io = IO.popen("tar --no-same-owner --no-same-permissions -xf #{sourcedir}/bower_components.tar.gz -C #{sourcedir}")
	io.close

    	Dir.glob(sourcedir + "/bower_components/**/*.tar.gz") do |dir|
		dir1 = dir.gsub(dir.gsub(/^.*\//,''),'')
        	io1 = IO.popen("tar --no-same-owner --no-same-permissions -xf #{dir} -C #{dir1}")
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
    
    Dir.glob(buildroot + "/**/*") do |f|
        if f.end_with?(".c") || f.end_with?(".cc") || f.end_with?(".cpp")
            name = f.gsub(/^.*node_modules\//,'').gsub(/\/.*$/,'')
            prefix = f.gsub(buildroot,'').gsub(/#{name}\/.*$/,'')
            prefix = buildroot + prefix + name
            buildlist << prefix
        end
    end
    
    buildlist = ( buildlist.uniq! if buildlist.uniq! ) || buildlist

    buildlist.each do |b|
	gyp = Dir.glob(b + "/**/*").select{|f| f.end_with?(".gyp")}
	node = Dir.glob(b + "/**/*").select{|f| f.end_with?(".node")}
	if ! gyp.empty? && ! node.empty?
          io = IO.popen("pushd #{b} && npm build -f && popd")
	  io.each_line {|l| puts l}
	  io.close
	elsif ! gyp.empty? && node.empty?
	  node_gyp = Dir.glob("/usr/lib*/node_modules/npm/node_modules/node-gyp/bin")[0] + "/node-gyp.js"
	  io1 = IO.popen("pushd #{b} && #{node_gyp} rebuild && popd")
          io1.each_line {|l| puts l}
          io1.close
        end
    end
    
when "--copy"
    Dir.glob(buildroot + "/**/*") do |dir|
        name = dir.gsub(/^.*\//,'')
        Dir.glob(sourcedir + "/" + name + "/*") do |f|
	    recursive_copy(f,dir)
        end
    end

    # rename    
    Dir.glob(buildroot + "/**/*").sort{|x| x.size}.each do |dir|
        name = dir.gsub(/^.*\//,'')
	prefix = dir.gsub(buildroot,'').gsub(name,'')
        if name.index(/-[0-9]\.[0-9]/)
                FileUtils.mv dir,buildroot + prefix + name.gsub(/-[0-9].*$/,'')
        end
    end

    # auto symlink executables in bin to /usr/bin
    Dir.glob(buildroot + "/**/*") do |f|
	unless f.split("/").grep("bin").empty? || f.end_with?(".node")
	  if File.file?(f) && File.executable?(f)
		FileUtils.mkdir_p buildroot + "/usr/bin" unless Dir.exist?(buildroot + "/usr/bin")
		name = f.gsub(/^.*\/bin\//,'')
		prefix = f.gsub(buildroot,'').gsub(/#{name}$/,'')
		puts "Linking #{prefix}#{name} to /usr/bin/#{name}"
		FileUtils.ln_sf prefix + name, buildroot + "/usr/bin/" + name
	  end
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
 
when "--clean"

  # clean source files
  Dir.glob(buildroot + sitelib + "/**/{*,.*}") do |f|
    if f.end_with?(".c") || f.end_with?(".h") || f.end_with?(".cc") || f.end_with?(".cpp") || f.end_with?(".o") || f.gsub(/^.*\//,'').start_with?(".") || f.end_with?("Makefile") || f.end_with?(".mk") || f.end_with?(".gyp") || f.end_with?(".gypi")
	puts "Cleaning " + f
	FileUtils.rm_rf f
    end
    unless f.index("build/Release")
      if File.file?(f) && File.executable?(f) && f.split("/").grep("bin").empty?
        puts "Fixing permission: " + f
        io = IO.popen("chmod -x #{f}")
        io.close
      end
    else
	FileUtils.rm_rf f if f.index("obj.target")
    end
  end

  # clean empty directories
  Dir[buildroot + sitelib + "/**/{*,.*}"].select{|d| File.directory? d}.select{|d| (Dir.entries(d) - %w[ . .. ]).empty?}.each{|d| Dir.rmdir d}

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

