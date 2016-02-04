#!/usr/bin/env ruby

require 'rubygems'
require 'json'

str = ''
pkgname = ARG[0]
pkgname = (pkgname.gsub(/\/$/) if pkgname.index(/\/$/)) || pkgname
nodedir = '/usr/lib/node_modules/'
pkgdir = nodedir + pkgname
localmoduledir = pkgdir + '/node_modules'

open(pkgdir + "/package.json",'r:UTF-8') {|f| str = f.read}
json = JSON.parse(str)

Dir.mkdir("node_modules")

dep = ""

json["dependencies"].each do |d|
	dep = d.shift
	if Dir.glob(nodedir + dep)
	    unless File.exists?("node_modules/" + dep)
		File.symlink(nodedir + dep, "node_modules/" + dep)
	    end
	end
end

