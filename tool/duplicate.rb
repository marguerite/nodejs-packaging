module Duplicate

# find duplicate directories and rename them to "name@version"

	require 'fileutils'

	def self.find(path="")

		list,arr,uni,dup = [],[],[],[]
		path = Dir.pwd + "/" + path + "/**/*.json"
		Dir.glob(path) do |pa|
			list << pa
		end
		list.each_index {|i| arr[i] = list[i].gsub(/^.*\//,'')}
		uni = arr.uniq
		dup = arr.select {|i| uni[arr.find_index(i)] != nil }
		dup = dup.uniq

		dupli = list.select {|i|
			a = dup.select {|j| i.index(j) }
			! a.empty?
		}

		return dupli

	end

	def self.rename(path="")

		dup = self.find(path)
		dup.each do |d|
			name = d.gsub(/^.*\//,'')
			ver = name.gsub('.json','').gsub(/^.*-/,'')
			left = d.gsub(name,'').gsub(/\/(?=$)/,'')
			newpath = left + "@" + ver
			FileUtils.mv d,newpath
		end

	end

end

Duplicate.rename("forever")
