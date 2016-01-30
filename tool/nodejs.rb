#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative 'parent.rb'

str = ''
Dir.glob("**/*.json") do |j|
	open(j) do |f|
		str = f.read
	end
end
json = JSON.parse(str)
$workspace = "/home/marguerite/Public/nodejs-packaging/tool"

def recursive_mkdir(json={},workspace=$workspace)

	p json

	json.keys.each do |k|
		puts "creating #{workspace}/#{k}"
		FileUtils.mkdir_p workspace + "/" + k
		if json[k].keys.include?("dependencies")
			i = json[k]["dependencies"]
			w = workspace + "/" + k
			recursive_mkdir(json=i,workspace=w)
		end
	end

end

recursive_mkdir(json,$workspace)
