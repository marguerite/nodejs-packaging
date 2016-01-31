#!/usr/bin/env ruby

require 'json'

if File.directory?("/usr/src/packages") & File.writable?("/usr/src/packages")
        topdir = "/usr/src/packages"
else
        topdir = ENV["HOME"] + "/rpmbuild"
end
buildroot = Dir.glob(topdir + "/BUILDROOT/*")[0]

## all directories

files = []
Dir.glob(buildroot + "/**/package.json") do |f|
	files << f
end

pkgname = ARGV[0]
dep = ARGV[1]
pkgjson = ""
jsstr = ""

files.each do |f|
	pkgjson = f if f.index(pkgname + "/package.json")
end

# get its parent
pkgjson = pkgjson.gsub('node_modules/' + pkgname + '/package.json','') + "package.json"

File.open(pkgjson,'r:UTF-8') {|f| jsstr = f.read}
json = JSON.parse(jsstr)

json["dependencies"][pkgname] = dep

File.open(pkgjson,'w:UTF-8') {|f| f.write JSON.pretty_generate(json) }
