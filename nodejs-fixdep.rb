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
    if f.index(pkgname + "/package.json")
        # get its parent
        pkgjson = f.gsub('node_modules/' + pkgname + '/package.json','') + "package.json"
	if File.exist? pkgjson
          File.open(pkgjson,'r:UTF-8') {|f| json = JSON.parse(f.read)}
	  if ARGV[0] == "--drop"
	    json["dependencies"].delete_if {|k,v| k == pkgname}
	  else
	    json["dependencies"][pkgname] = dep
	  end
	  File.open(pkgjson,'w:UTF-8') {|f| f.write JSON.pretty_generate(json) }
	end
    end
end
