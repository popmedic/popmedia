require 'mongrel'
require 'json'
require_relative './cfg.rb'

class StatHandler < Mongrel::HttpHandler
	def initialize(doc_root, data_root, media_types, av_types, a_types)
		@doc_root = doc_root
		@data_root = data_root
		@media_types = media_types 
		@av_types = av_types
		@a_types = a_types
	end
	def process(req, res)
		res.start(200) do |head,out|
			begin
				head["Content-Type"] = "text/json"
				rtn = Hash.new
				rtn["av_count"] = 0
				rtn["a_count"] = 0
				rtn["media_count"] = 0
				path = URI.unescape(req.params["REQUEST_PATH"]).gsub(/^\/stat\/{0,1}/, '').gsub(/\/$/, '')
				if(/^#{@doc_root}\//.match("%s/" % path) == nil)
      		raise "%s: NOT AN EXPOSED DIRECTORY!" % [path]
    		end
				filter = "%s/**{,/*/**}/*.{%s}" % [path.chomp('/'), @av_types.join(',')]
				rtn["av_count"] = Dir[filter].length
				filter = "%s/**{,/*/**}/*.{%s}" % [path.chomp('/'), @a_types.join(',')]
				rtn["a_count"] = Dir[filter].length
				rtn["media_count"] = rtn["av_count"] + rtn["a_count"]
				out << rtn.to_json
			rescue => e
				out << { "ERROR" => e.to_s }.to_json
			end
		end
	end
end