#!/usr/bin/env ruby

# it will randomly pick <N> packages from <repo>
# to branched repository like home:MargueriteSu:branches:devel:languages:nodejs
# to test nodejs-packaging

# ARGV[0]: repository name
# ARGV[1]: number of N

repo = ARGV[0] || "devel:languages:nodejs"
if ARGV[0]
	number = ARGV[1] || 10
else
	number = ARGV[0] || 10
end

# get packages

list = []

io = IO.popen("osc list #{repo}")
io.each_line {|i| list << i.strip!}
io.close

list.reject! {|i| ! i.include?("nodejs")}

# branched 

size = list.size

number.times do

	io = IO.popen("osc branch #{repo} #{list[rand(size.to_i)]}")
	io.each_line {|i| puts i}
	io.close

end
