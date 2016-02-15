require 'json'
require 'net/https'

#https://build.opensuse.org/source/devel:languages:nodejs/mocha/mocha.json

OBS = "https://build.opensuse.org"
REPO = "devel:languages:nodejs"
pkgs = []

IO.popen("osc list #{REPO}") do |i|
  i.each_line {|l| pkgs << l.strip unless l.index("nodejs-") || l.strip == "nodejs" || l.strip == "scons" || l.strip == "phantomjs" || l.strip.index("ruby")}
end

def login(username="",password="")

	uri = URI.parse(OBS + "/user/login")

	http = Net::HTTP.new(uri.host,uri.port)
	http.use_ssl = true
	http.basic_auth username,password
	resp = http.get(uri.path)
	cookie = resp.response['set-cookie']

	p resp.code
	p cookie

end

def json_exist?(pkg="")

	uri = URI.parse(OBS + "/source/" + REPO + "/" + pkg + "/" + pkg + ".json")

	http = Net::HTTP.new(uri.host,uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	req = Net::HTTP::Get.new(uri.request_uri)
	req.basic_auth 'MargueriteSu','Zzl612'
	resp = http.request(req)
	
	#p resp.status
	p resp.body
	return resp.status

end

login("MargueriteSu","Zzl612")
#json_exist?("mocha")
