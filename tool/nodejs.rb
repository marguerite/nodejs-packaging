#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative 'parent.rb'

str = ''
Dir.glob("**/*.json") do |j|
	open(j) do |f|
#	open('test.json') do |f|
		str = f.read
	end
end
json = JSON.parse(str)
$workspace = "/home/marguerite/Public/nodejs-packaging/tool"

def recursive_mkdir(json={},workspace=$workspace)

    json.keys.each do |key|
	puts "creating #{workspace}/#{key}"
	FileUtils.mkdir_p workspace + "/" + key
	unless json[key] == nil
		if json[key].keys.include?("dependencies")
			json[key]["dependencies"].each do |k,v|
				i = {}
				i[k] = v
				recursive_mkdir(i,workspace + "/" + key)
			end
		end
	end
    end

end

recursive_mkdir(json,$workspace)
