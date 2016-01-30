#!/usr/bin/env ruby

# The ultimate awesome Nodejs packaging tool like a supernova!

require_relative 'dependencies.rb'
include Dependencies

workspace = Dir.pwd

# generate dependency map and downloadable filelist
Dependencies.write(ARGV[0])



