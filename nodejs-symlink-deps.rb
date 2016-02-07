#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'fileutils'
require_relative 'nodejs/bundles.rb'
include Bundles

buildroot = Bundles.getbuildroot
sitelib = Bundles.getsitelib

json = {}
pkgname = ARG[0]
pkgname = (pkgname.gsub(/\/$/) if pkgname.index(/\/$/)) || pkgname
locallib = buildroot + sitelib + '/' + pkgname + '/node_modules'

open(buildroot + sitelib + '/' + pkgname + "/package.json",'r:UTF-8') {|f| json = JSON.parse(f.read)}

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

