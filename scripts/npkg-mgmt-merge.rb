#!/usr/bin/env ruby

require 'json'

jsonname,jsonversion = ARGV[0],ARGV[1]

jsonlist,sourcelist,licenselist = [],[],[]
json,source,license = [],[],""

if ARGV.include?("-i")

	start = ARGV.find_index("-i")

	jsonlist = ARGV[start..-1].delete_if {|i| i == "-i"}

end

jsonlist.each do |l|

	sourcelist << l.gsub(".json",".source")
	licenselist << l.gsub(".json",".license")

end

# merge jsons

jsonlist.each do |l|

	open(l) do |f|

		json << JSON.parse(f.read).to_s.gsub(/^\{/,'').gsub(/\}$/,'').gsub("=>",":")

	end

end

huge = "{\"#{jsonname}\":{\"version\":\"#{jsonversion}\",\"dependencies\":{"

json.each do |l|

	huge += l + ","

end

huge = huge.gsub(/,$/,'') + "}}}"

final = JSON.parse(huge)

open(jsonname + ".json","w") do |f|
	f.write JSON.pretty_generate(final)
end

# merge sources

i = 1
mid = []

sourcelist.each do |s|

	open(s) do |f|

		f.each_line do |l|

			a = l.gsub(/^Source.*:/,"")
			mid << a

		end

	end

end

mid = ( mid.uniq! if mid.uniq! ) || mid
p mid

open(jsonname + ".source","w") do |f|
	mid.each do |m|
		f.write "Source#{i}:\t\thttp:" + m
		i += 1
	end
end

# merge licenses

licenselist.each do |li|

	open(li) do |f|
		a = f.read.strip
		unless li == licenselist.last
			license += a + " and "
		else
			license += a
		end
	end

end

la = license.split(" and ")
la = ( la.uniq! if la.uniq! ) || la

open(jsonname + ".license","w") do |f|
	la.each do |i|
		unless i == la.last
			f.write i + " and "
		else
			f.write i
		end
	end
end
