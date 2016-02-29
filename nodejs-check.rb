require 'json'

# check where a module comes from
mod = ARGV[0]

if mod
  Dir.glob("./**/package.json") do |f|
    open(f) do |file|
      json = JSON.parse(file.read)
      unless json["dependencies"].nil?
        puts f if json["dependencies"].include?(name)
      end
    end
  end
end

# check left-over bower.json dependencies
Dir.glob("./**/*") do |f|
  if f.end_with?("bower.json")
    open(f) do |file|
      json = JSON.parse(file.read)
      unless json["dependencies"].nil? || json["dependencies"].empty?
	puts f.gsub(/^.*node_modules\//,'').gsub(/\/bower\.json/,'') + " has dependencies in bower.json, please do something"
      end
    end
  end
end
