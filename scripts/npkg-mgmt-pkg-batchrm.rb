#!/usr/bin/env ruby
require 'fileutils'

# run in repository workspace on your local machine,
# to drop useless packages, it will:
# 1. delete the previous built RPMs on build service servers
# 2. remote delete the package in the naming project
# 3. remove the package's working directory on your local machine
# 4. clean the repo metadata on your local machine
# you have to have a "packages.txt" first, which can
# be generated using `osc list <prj> | grep <keywords>`
# command or can be written manually.

array = []

File.open("packages.txt",'r:UTF-8') do |f|
	f.each_line do |l|
		array << l.strip!
	end
end

array.each do |a|

	io2 = IO.popen("osc wipebinaries --all devel:languages:nodejs #{a}")
	io2.each_line {|l| puts l}
	io2.close

	io1 = IO.popen("osc rdelete devel:languages:nodejs #{a} -m \"deleted\"")
	io1.each_line {|l| puts l}
	io1.close

	if Dir.glob("./#{a}")

		FileUtils.rm_rf "/home/marguerite/Public/home:MargueriteSu:branches:devel:languages:nodejs/#{a}"	

	end

	io = IO.popen("sed -i \"/#{a}/d\" .osc/_packages")
	io.each_line {|l| puts l}
	io.close

end
