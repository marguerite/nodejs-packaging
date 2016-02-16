module Bower

	require 'json'
	require_relative "../download.rb"
	include Download

	def dependency(name="")

		json = {}

		# unpack
		io = IO.popen("tar -xf #{name}-*.tgz")
		io.close

		if File.exist?("package/bower.json")

			open("package/bower.json") {|f| json = JSON.parse(f.read)}

		end

		return json["dependencies"]

	end

	def lookup(name="")

		json = dependency(name)

	end

	module_function :dependency,:lookup

end

p Bower.lookup("tryton-sao")
