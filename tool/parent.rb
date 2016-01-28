require 'json'
	    str = ""
	    File.open('1.json') {|f| str = f.read }
	    json = JSON.parse(str)

        $path = []

	def find(json={}, parent="")

	    unless json == nil

	    unless json.key?(parent)
		$path << json.keys[0]
		find(json.values[0]["dependencies"],parent)
	    end

	    return $path

	    end

	end

find(json,"adm-zip")
