require 'mongrel'
require 'json'
require_relative './info.rb'

class InfoHandler < Mongrel::HttpHandler
  def initialize doc_root='', data_root='', apache_path=false, types=[], av_types=[], a_types=[]
    @doc_root = doc_root
    @data_root = data_root
    @apache_path = apache_path
    @media_types = types
    @av_types = av_types
    @a_types = a_types
  end
  def process(req, res)
    res.start(200) do |head,out|
      begin
    		puts ("incoming: %s" % req.params["REQUEST_PATH"])
        path = URI.unescape(req.params["REQUEST_PATH"]).gsub(/^\/info\/{0,1}/, '').gsub(/\/$/, '')
        fmt = "html"
        if($FMT != nil)
          if($FMT.include?(File.basename(path)))
            fmt = File.basename(path)
            cfmt = "/%s" % [fmt]
            path = path.chomp(cfmt)
          end
        end
        head["Content-Type"] = "text/%s" % [fmt]
        info = Info.new(path, @doc_root, @data_root, @apache_path, @media_types, @av_types, @a_types)
        if(fmt == "html")
          out << info.to_html
        elsif(fmt == "json")
          out << info.to_json
        elsif(fmt == "xml")
          out << info.to_xml
        end
      rescue Exception => e
        out << {"ERROR" => e.to_s}.to_json
      end
    end
  end
end