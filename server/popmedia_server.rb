#!/usr/local/bin/ruby

require 'webrick'

$DEBUG_POP = true
$OUT_FMT = ".json"

class PopMedia_Server
  def initialize
    @port = 8080
    @doc_root = Dir::pwd
    @server_name = Socket.gethostname
    @ip_addr = IPSocket.getaddress(@server_name)
    @server = WEBrick::HTTPServer.new(
      {
        :Port         => @port,
        :DocumentRoot => @doc_root
      }
    )
  end
  def now
    return Time.now.to_s.sub(/ [\-\+][0-9]{4}$/, '')
  end
  def start
    trap("INT"){ @server.shutdown }
    puts "[%s] INFO  Running on %s(%s:%s)" % [self.now, @server_name, @ip_addr, @port]
    #@server.mount '/dir', DirServlet
    #@server.mount '/info', InfoServlet
    #@server.mount '/admin', AdminServlet
    @server.start
  end
end

s = PopMedia_Server.new
s.start