#!/usr/local/bin/ruby
require 'webrick'
require "rexml/document"
require "./dirlet.rb"
require "./streamlet.rb"

$CFGFNAME = 'config.xml'
$DEBUG_POP = true

class PopMedia_Server
  def initialize
    load_cfg
    @mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
    @mime_types.store("mp4", "video/mpeg")
    @mime_types.store("mp3", "audio/mpeg")
    @server_name = Socket.gethostname
    @ip_addr = IPSocket.getaddress(@server_name)
    @server = WEBrick::HTTPServer.new(
      {
        :Port         => @port,
        :DocumentRoot => @doc_root,
        :MimeTypes    => @mime_types
      }
    )
  end
  def load_cfg
    cfgfile = File.new $CFGFNAME
    @cfgxml = REXML::Document.new cfgfile
    @port      = cfg_safe_get('/configuration/port'     , '8080').to_i
    @doc_root  = cfg_safe_get('/configuration/doc_root' , "%s/exposed" % Dir::pwd)
    @data_root = cfg_safe_get('/configuration/data_root', "%s/data" % Dir::pwd)
    @media_types = Array.new
    @av_types = Array.new
    @a_types= Array.new
    @cfgxml.root.elements.each("/configuration/media_types/type") do |element|
      @media_types << element.text.downcase
      kind = element.attributes["kind"]
      if kind != nil
        if(kind == "av")
          @av_types << element.text.downcase
        elsif(kind == "a")
          @a_types << element.text.downcase
        end
      end
    end
  end
  def start
    trap("INT") do 
      @server.shutdown 
    end
    puts "[%s] INFO  Running on %s(%s:%s)" % [self.now, @server_name, @ip_addr, @port]
    puts "[%s] INFO  Exposed: %s" % [now, @doc_root]
    puts "[%s] INFO     Data: %s" % [now, @data_root]
    @media_types.each do |type| puts "[%s] INFO     Type: %s" % [now, type] end
    @av_types.each do |type| puts    "[%s] INFO   AVType: %s" % [now, type] end
    @a_types.each do |type| puts     "[%s] INFO    AType: %s" % [now, type] end
    @server.mount '/dir', Dirlet, @doc_root, @data_root, @media_types
    @server.mount '/stream', Streamlet
    #@server.mount '/info', InfoServlet
    #@server.mount '/admin', AdminServlet
    @server.start
  end
  def cfg_safe_get(xpath, dflt='')
    rtn = @cfgxml.root.elements[xpath].text
    if(!rtn) 
      rtn = dflt
    end
    return rtn
  end
  def now
    return Time.now.to_s.sub(/ [\-\+][0-9]{4}$/, '')
  end
end

s = PopMedia_Server.new
s.start