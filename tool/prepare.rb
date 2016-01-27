#!/usr/bin/env ruby

require_relative 'pkgjson.rb'
include PKGJSON
require 'fileutils'

name = ARGV[0]

$i = 0

def recursive_download(name="",comparator="")

	Dir.mkdir(name) unless Dir.exists? name
	old = Dir.pwd
	Dir.chdir name

	comparator = "*" if comparator == nil

	json = PKGJSON.get(name,comparator)

	unless json["dependencies"] == nil || json["dependencies"].empty?
		json["dependencies"].each do |k,v|
			puts "Downloading #{$i}: #{k}"
			recursive_download(k,v)
		end
	end

	Dir.chdir(old)

	$i += 1

end

recursive_download(name)

# move all tgz here
#Dir.glob(name + "/**/*") do |f|
#	FileUtils.mv(f,Dir.pwd) if f.index(".tgz")
#end

