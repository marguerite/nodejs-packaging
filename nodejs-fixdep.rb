#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require '/usr/lib/rpm/nodejs/bundles.rb'
include Bundles

buildroot = Bundles.getbuildroot

## all directories

files = []
Dir.glob(buildroot + "/**/package.json") do |f|
	files << f
end

if ARGV[0] == "--drop"
  pkgname = ARGV[1]
  dep = nil
else
  pkgname = ARGV[0]
  dep = ARGV[1]
end
pkgjson = ""
json = {}

files.each do |f|
  if ARGV[0] == "--drop"
    # sometime the module needs to drop wasn't copyed to buildroot at all
    File.open(f,'r:UTF-8') {|f| json = JSON.parse(f.read)}
    unless json["dependencies"].nil?
      unless json["dependencies"].keys.index(pkgname).nil?
	json["dependencies"].delete_if {|i| i == pkgname}
	File.open(f,'w:UTF-8') {|f1| f1.write JSON.pretty_generate(json) }
      end
    end
  else
    if f.index(pkgname + "/package.json")
        # get its parent
        pkgjson = f.gsub('node_modules/' + pkgname + '/package.json','') + "package.json"
	if File.exist? pkgjson
          File.open(pkgjson,'r:UTF-8') {|f1| json = JSON.parse(f1.read)}
	  json["dependencies"][pkgname] = dep
	  File.open(pkgjson,'w:UTF-8') {|f2| f2.write JSON.pretty_generate(json) }
	end
    end
  end
end
