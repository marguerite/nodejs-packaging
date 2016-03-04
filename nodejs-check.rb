#!/usr/bin/env ruby
require 'json'

require '/usr/lib/rpm/nodejs/bundles.rb'
include Bundles

buildroot = Bundles.getbuildroot
sitelib = Bundles.getsitelib

# check where a module comes from
mod = ARGV[0]

unless mod.nil?
  Dir.glob(buildroot + sitelib + "/**/package.json") do |f|
    open(f,"r:UTF-8") do |file|
      json = JSON.parse(file.read)
      unless json["dependencies"].nil?
        puts f if json["dependencies"].include?(mod)
      end
    end
  end
end

# check left-over bower.json dependencies
Dir.glob(buildroot + sitelib + "/**/*") do |f|
  if f.end_with?("bower.json")
    open(f,"r:UTF-8") do |file|
      json = JSON.parse(file.read)
      unless json["dependencies"].nil? || json["dependencies"].empty?
	puts f.gsub(/^.*node_modules\//,'').gsub(/\/bower\.json/,'') + " has dependencies in bower.json, please do something"
      end
    end
  end
end
