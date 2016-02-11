module Download

# download file with name

	require 'net/http'

	def self.get(url='')

		path = url.gsub(/^.*\.(com|org)/,'')
		file = url.gsub(/^.*\//,'')
		uri = URI(url.gsub(path,''))
		obj = Net::HTTP.new(uri.host,uri.port)
		obj.use_ssl = true if uri.scheme == 'https'
		begin
			obj.start do |http|
				http.read_timeout = 500
				http.request_get path do |resp|
					open(file,'w') do |io|
						resp.read_body do |chunk|
							io.write chunk
						end
					end
				end
			end
		rescue => e
			raise "=> Exception: '#{e}'. Skipping download."
		end

		return file

	end

end

