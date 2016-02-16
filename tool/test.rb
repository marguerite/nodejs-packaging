require 'fileutils'
Dir.glob("bower_components/*") do |dir|
	io1 = IO.popen("tar -xf #{dir}/*.tar.gz -C #{dir}")
	io1.close
	FileUtils.rm_rf "#{dir}/*.tar.gz"
	dir1 = ""
	Dir.glob(dir + "/*") {|i| dir1 = i unless i.index(".tar.gz")}
	io2 = IO.popen("cp -r #{dir1}/* #{dir}/")
	io2.close
	FileUtils.rm_rf dir1
end
