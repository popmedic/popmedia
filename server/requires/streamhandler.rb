require 'mongrel'
require 'json'

class StreamHandler < Mongrel::HttpHandler
  def process(req, res)
    res.start(200) do |head,out|
      head["Connection"] = "Keep-Alive"
      path = URI.unescape(req.params["REQUEST_PATH"]).gsub(/^\/stream\/{0,1}/, '').gsub(/\/$/, '')
      head["Content-Type"] = IO.popen(["file", "--brief", "--mime-type", path], in: :close, err: :close).read.chomp
      head["Content-Length"] = File.size(path)
      begin
        f = File.new path
        puts "Streaming %s" % path
        f.each(10240) do |buf|
          res.send_status(1024)
          out << buf
          out.flush
        end
      rescue Exception => e
        out << {"ERROR" => e.to_s}.to_json
      end
    end
  end
end