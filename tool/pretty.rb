require 'json'
str = ''
open('test.json') {|f| str = f.read.gsub("=>",":") }
json = JSON.parse(str)
open('test.json','w:UTF-8') {|f| f.write JSON.pretty_generate(json)}
