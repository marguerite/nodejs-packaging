#!/usr/bin/env ruby

require 'json'
require 'node2rpm'

$buildroot = Node2RPM::System.buildroot
$sitelib = Node2RPM::System.sitelib

# check where a module comes from
def check_module_origin
  return if ARGV.empty?
  Dir.glob($buildroot + $sitelib + '/**/package.json') do |file|
    json = JSON.parse(open(file, 'r:UTF-8').read)
    next if json['dependencies'].nil? || !json['dependencies'].include?(ARGV[0])
    r = file.match(%r{^.*/(.*?)/package\.json})
    puts r[1]
  end
end

check_module_origin

# check left-over bower.json dependencies
def left_bower_dependencies
  files = Dir.glob($buildroot + $sitelib + '/**/bower_components/*')
             .select { |x| File.directory?(x) }
             .map! { |x| File.basename(x) }
  Dir.glob($buildroot + $sitelib + '/**/*') do |file|
    next unless file =~ %r{bower_components/.*/bower.json$}
    json = JSON.parse(open(file, 'r:UTF-8').read)
    next if json['dependencies'].nil?
    json['dependencies'].keys.each do |k|
      puts "#{file} has unmet bower dependency #{k}" unless files.include(k)
    end
  end
end

left_bower_dependencies
