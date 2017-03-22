#!/usr/bin/env ruby

require 'json'
require 'node2rpm'
require 'optparse'
require 'ostruct'

buildroot = Node2RPM::System.buildroot
sitelib = Node2RPM::System.sitelib
jsons = Dir.glob(buildroot + sitelib + '/**/package.json')
options = OpenStruct.new

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: nodejs-fixdep -m <mod> -b <range> -a <range> -d <dir>
                 it will change the "module" with the "before" version
                 to the "after" version, and replace the current dir
                 in buildroot with provided one (can be skipped if not
                 bundled packaging).

                 nodejs-fixdep -m <mod> -a <range>
                 it will change all the named modules to the "after"
                 version.

                 nodejs-fixdep -m <mod> -b <range> -r
                 it will remove all the named modules will that version.

                 nodejs-fixdep -m <mod> -r
                 it will completely remove the named modules everywhere.

                 This macro should be used before %nodejs_filelist.'
  opts.separator ''
  opts.separator 'Specific Options:'

  opts.on('-m <mod>', '--module <mod>', 'Specify the module to fix (Required)') do |mod|
    options.mod = mod
  end

  opts.on('-b <range>', '--before <range>', 'Specify the current version (semver supported)') do |range|
    options.ver = range
  end

  opts.on('-a <range>', '--after <range>', 'Specify the fixed version (semver supported)') do |range|
    options.fix = range
  end

  opts.on('-r', '--remove', 'Remove the module') do
    options.removal = true
  end

  opts.on('-d <dir>', '--directory <dir>', 'Specify the directory to replace') do |dir|
    options.dir = dir
  end

  opts.separator ''
  opts.separator 'Common Options:'
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

parser.parse!(ARGV)

jsons.each do |js|
  json = JSON.parse(open(js, 'r:UTF-8').read)
  next if json['dependencies'].nil? || json['dependencies'].empty? || !json['dependencies'].keys.include?(options.mod)
  next if !options.ver.nil? && json['dependencies'][options.mod] != options.ver
  dirs = Dir.glob(File.split(js)[0] + "/node_modules/#{options.mod}")
  if options.removal
    json['dependencies'].delete(options.mod)
    FileUtils.rm_rf dirs[0] unless dirs.nil?
  else
    raise 'you should specify a fix' if options.fix.nil?
    json['dependencies'][options.mod] = options.fix
    FileUtils.rm_rf(dirs[0]) && FileUtils.mv(options.dir, dirs[0]) unless options.dir.nil? || dirs.nil?
  end
  open(js, 'w:UTF-8') { |f| f.write JSON.pretty_generate(json) }
end
