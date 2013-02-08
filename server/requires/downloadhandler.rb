require 'mongrel'
require 'json'

class DownloadHandler < Mongrel::HttpHandler
  def initialize doc_root='exposed', data_root='data', apache_path=false, types=['mp4', 'mp3']
    @doc_root = doc_root
    @data_root = data_root
    @media_types = types
    @apache_path = apache_path
  end
  def process(req, res)
    res.start(200) do |head,out|
      begin
        path = URI.unescape(req.params["REQUEST_PATH"]).gsub(/^\/download\/{0,1}/, '').gsub(/\/$/, '')
        if(/^#{@doc_root}\//.match("%s/" % path) == nil)
		  raise "%s: NOT IN AN EXPOSED DIRECTORY!" % [path]
		end
        fmt = "html"
        if($FMT != nil)
          if($FMT.include?(File.basename(path)))
            fmt = File.basename(path)
            cfmt = "/%s" % [fmt]
            path = path.chomp(cfmt)
          end
        end
        head["Content-Type"] = "text/%s" % [fmt]
        crate = Crate.new(path, @doc_root, @data_root, @apache_path, @media_types)
        if(fmt == "html")
          out << crate.to_html
        elsif(fmt == "json")
          out << crate.to_json
        elsif(fmt == "xml")
          out << crate.to_xml
        end
      rescue Exception => e
        out << {"ERROR" => e.to_s}.to_json
      end
    end
  end
end