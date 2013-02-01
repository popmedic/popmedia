#!/usr/local/bin/ruby

$FMT = ['html','xml','json']
$CFGFNAME = 'config.xml'
$DEBUG_POP = true

require 'mongrel'
require "rexml/document"
require "./requires/cratehandler.rb"
require "./requires/infohandler.rb"
require "./requires/searchhandler.rb"
require "./requires/streamhandler.rb"

class PopMedia_Server
  def initialize
    load_cfg
    @server_name = Socket.gethostname
    @ip_addr = IPSocket.getaddress(@server_name)
  end
  def load_cfg
    cfgfile = File.new $CFGFNAME
    @cfgxml = REXML::Document.new cfgfile
    @port      = cfg_safe_get('/configuration/port'     , '8080').to_i
    @doc_root  = cfg_safe_get('/configuration/doc_root' , "%s/exposed" % Dir::pwd)
    @data_root = cfg_safe_get('/configuration/data_root', "%s/data" % Dir::pwd)
    @media_types = Array.new
    @av_types = Array.new
    @a_types = Array.new
    @apache_path = cfg_safe_get('/configuration/apache_path', false)
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
    @server = Mongrel::HttpServer.new(@ip_addr, @port.to_s)
    trap("INT") do 
      puts "\n[%s] INFO  Stopping server: %s(%s:%s)" % [self.now, @server_name, @ip_addr, @port]
      @server.stop 
    end
    
    puts "[%s] INFO  Running on %s(%s:%s)" % [self.now, @server_name, @ip_addr, @port]
    puts "[%s] INFO  Exposed: %s" % [now, @doc_root]
    puts "[%s] INFO     Data: %s" % [now, @data_root]
    @media_types.each do |type| puts "[%s] INFO     Type: %s" % [now, type] end
    @av_types.each do |type| puts    "[%s] INFO   AVType: %s" % [now, type] end
    @a_types.each do |type| puts     "[%s] INFO    AType: %s" % [now, type] end
    
    @server.register('/stream', StreamHandler.new)
    @server.register('/search', SearchHandler.new(@doc_root, @data_root, @apache_path, @media_types))
    @server.register('/crate', CrateHandler.new(@doc_root, @data_root, @apache_path, @media_types))
    @server.register('/info',   InfoHandler.new(@doc_root, @data_root, @apache_path, @media_types, @av_types, @a_types))
    
    Mongrel::DirHandler::add_mime_type('.mp4', 'video/mp4')
    Mongrel::DirHandler::add_mime_type('.mp3', 'audio/mp3')
    @server.register("/%s" % [@doc_root], Mongrel::DirHandler.new(@doc_root))
    @server.register("/%s" % [@data_root], Mongrel::DirHandler.new(@data_root))
    @server.register("/images", Mongrel::DirHandler.new("images"))
    @server.register("/html", Mongrel::DirHandler.new('index.html'))
    
    @server.run.join
  end
  def cfg_safe_get(xpath, dflt='')
    rtn = false
    e = @cfgxml.root.elements[xpath]
    if(e)
      rtn = e.text
    end
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