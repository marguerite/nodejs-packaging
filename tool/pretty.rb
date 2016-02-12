require 'json'
json = {}
open('test.json') {|f| json = JSON.parse(f.read.gsub("=>",":")) }
open('test.json','w:UTF-8') {|f| f.write JSON.pretty_generate(json)}
