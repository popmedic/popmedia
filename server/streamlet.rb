require "webrick"

class Streamlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res["content-type"] = "application/octet-stream"
    path = req.path.gsub(/^\/stream\/{0,1}/, '').gsub(/\/$/, '')
    f = File.new(path, "r")
    r, w = IO.pipe
    res.body = r
    Thread.start do
      while(l = f.gets) do
        w.write(l)
      end
      w.close
    end
  end
end