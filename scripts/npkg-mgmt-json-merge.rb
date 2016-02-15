#!/usr/bin/env ruby

require 'json'

jsonname,jsonversion,list,jsonlist = ARGV[0],ARGV[1],[],[]

if ARGV.include?("-i")

	start = ARGV.find_index("-i")

	list = ARGV[start..-1].delete_if {|i| i == "-i"}

end

list.each do |l|

	open(l) do |f|

		jsonlist << JSON.parse(f.read).to_s.gsub(/^\{/,'').gsub(/\}$/,'').gsub("=>",":")

	end

end

huge = "{\"#{jsonname}\":{\"version\":\"#{jsonversion}\",\"dependencies\":{"

jsonlist.each do |l|

	huge += l + ","

end

huge = huge.gsub(/,$/,'') + "}}}"

final = JSON.parse(huge)

open(jsonname + ".json","w") do |f|
	f.write JSON.pretty_generate(final)
end
