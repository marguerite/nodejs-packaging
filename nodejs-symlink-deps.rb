#!/usr/bin/env ruby

# symlink is a two way thing: link modules in this package to the global sitelib;
# or link global modules back here:
# 1. for bundled packaging, the later is needless, because our package contains
#    a full dependency cycle. but if you want to link some modules to the global
#    sitelib (like `npm link (in package dir)` will do), you can run:
#    'nodejs-symlink-deps -b -m a,b,c'.
# 2. for single packaging, the later is a must. because `npm link <module>` may
#    be applied to our package. so it becomes local dependency for another module.
#    but remember we don't have any bundled dependencies. so we can't run ourselves.
#    symlinking every dependency in package.json will do the trick.
#    so for single packaging, just run 'nodejs-symlinks-deps' itself.

require 'json'
require 'fileutils'
require 'node2rpm'
require 'optparse'
require 'ostruct'

buildroot = Node2RPM::System.buildroot
sitelib = Node2RPM::System.sitelib
options = OpenStruct.new

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: nodejs-symlink-deps -b -m a,b,c
                 it will symlink the bundled dependencies in node_modules
                 to the global sitelib. it is useful if you want this
                 package to also provide some other modules.
                 
                 or nodejs-symlink-deps without any parameter will creating
                 false symlinks (the source may not exist on your system at
                 all) for every dependency in package.json, from the global
                 sitelib to your package\'s node_modules.

                 it is useful for single packaging because package doesn\'t
                 contain any dependencies itself, and every installed module
                 has global access in that case. (we don\'t care if it\'s
                 installed, it\'s the job for nodejs.req) so `npm link <module>`
                 will work now because dependencies needed are symlinked.'
  opts.separator ''
  opts.separator 'Specific Options:'

  opts.on('-b', '--bundle-mode', 'Specify if this package has bundled dependencies') do
    options.bundle = true
  end

  opts.on('-m <array>', '--modules <array>', Array, 'Specify the modules to be linked to global sitelib') do |mods|
    options.mods = mods
  end

  opts.on('-v <array>', '--versions <array>', Array, 'Specify the versions for the above modules, they have to match') do |vers|
    options.vers = vers
  end

  opts.separator ''
  opts.separator 'Common Options:'
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

parser.parse!(ARGV)

if options.bundle
  raise 'you need to provide some modules to symlink!' if options.mods.nil?
  Dir.glob(buildroot + sitelib + '/**/package.json').each do |js|
    json = JSON.parse(open(js, 'r:UTF-8').read)
    next if json['dependencies'].nil? || json['dependencies'].empty?
    dedupe = json['dependencies'].keys & options.mods
    next if dedupe.empty?
    h = Hash[options.mods.zip(options.vers)] unless options.vers.nil?
    dedupe.each do |i|
      orig_dir = File.join(File.split(js)[0], i)
      dest_dir = File.join(buildroot + sitelib, i)
      ver = JSON.parse(open(File.join(orig_dir, 'package.json'), 'r:UTF-8').read)['version']
      next unless h.nil? || h[i] == ver
      if File.symlink?(orig_dir)
        Node2RPM.server.new.send :real_symlink, orig_dir, dest_dir
      else
        FileUtils.ln_sf orig_dir.sub(buildroot, ''), dest_dir
      end
    end
  end
else
  # single-mode packaging goes here.
  # FIXME: should write a new check in nodejs_check to see if symlink has been run
  pkg = Dir.glob(buildroot + sitelib + '/**/package.json').sort { |x| x.size }[0]
  path = File.join(File.split(pkg)[0], 'node_modules')
  raise 'node_modules directory already exists!
         this indicates this package contains \'bundleDependency\' provided
         upstream. the common practice is to remove the node_modules before
         running nodejs_symlink_deps. unless you got permission from openSUSE
         nodejs team, please DO NOT skip the nodejs_symlink_deps procedure
         for single-mode packaging. It\'s dangerous!
        ' if File.exist?(path)
  FileUtils.mkdir_p path
  json = JSON.parse(open(pkg, 'r:UTF-8').read)
  unless json['dependencies'].nil? || json['dependencies'].empty?
    # FIXME: should write a post macro to check if the version of the symlinked module
    # is the same as the version required here in package.json. because no way to check
    # that at build time.
    json['dependencies'].keys.each do |k|
      FileUtils.ln_sf File.join(sitelib, k), File.join(path, k)
    end
  end
end
