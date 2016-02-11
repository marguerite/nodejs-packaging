#!/usr/bin/env ruby

require 'json'

json = {}

Dir.glob('./*.json') do |f|
	open(f) {|f1| json = JSON.parse(f1.read) }
end

$keys = []

def flatten(json={})
    unless json == nil		
	if json.keys.size == 1
		$keys << "nodejs-" + json.keys[0]
		flatten(json.values[0]["dependencies"])
	else
		json.keys.each do |m|
			$keys << "nodejs-" + m
			flatten(json[m]["dependencies"])
		end
	end
    end
end

flatten(json)

$keys = ($keys.uniq! if $keys.uniq) || $keys

$pkgs = []
# get package list of devel:languages:nodejs
IO.popen("osc list devel:languages:nodejs") do |io|
	io.each_line {|i| $pkgs << i.strip!}
end

$keys = $keys.sort!
$pkgs = $pkgs.sort!

$result = $keys & $pkgs

unless $result.empty?
	open('packages.txt','w:UTF-8') do |f|
		$result.each {|k| f.write k + "\n"}
	end
end
