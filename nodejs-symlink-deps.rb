#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'fileutils'

if File.directory?("/usr/src/packages") & File.writable?("/usr/src/packages")
	topdir = "/usr/src/packages"
else
	topdir = ENV["HOME"] + "/rpmbuild"
end
buildroot = Dir.glob(topdir + "/BUILDROOT/*")[0]
sitelib = '/usr/lib/node_modules'

str = ''
pkgname = ARG[0]
pkgname = (pkgname.gsub(/\/$/) if pkgname.index(/\/$/)) || pkgname
locallib = buildroot + sitelib + '/' + pkgname + '/node_modules'

open(buildroot + sitelib + '/' + pkgname + "/package.json",'r:UTF-8') {|f| str = f.read}
json = JSON.parse(str)

if File.exists?(locallib)
	raise "node_modules exists for #{pkgname}. it's a bundled package that symlinks are handled differently".
else
	Dir.mkdir(locallib)
end

json["dependencies"].each do |d|
	if File.exists?(sitelib + '/' + d)
	    unless File.exists?(locallib + '/' + d)
		FileUtils.ln_sf(sitelib + '/' + d, locallib + '/' + d)
	    end
	end
end

