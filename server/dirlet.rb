require 'json'

class DirectoryItem
  def initialize(name, link, href, image, kind)
    @hash = {"name" => name, "link" => link, "href" => href, "image" => image, "kind" => kind}
  end
  def to_json
    return @hash.to_json
  end
  def to_html
    return "<a href=\"%s\"><img src=\"%s\"/>%s (%s)</a>" % [@hash["href"], @hash["image"], @hash["name"], @hash["kind"]]
  end
end
class Directory
  def initialize(path, doc_root='', data_root='', types=[])
    @doc_root = doc_root
    if(/^#{@doc_root}\//.match("%s/" % path) == nil)
      raise "%s: NOT AN EXPOSED DIRECTORY!" % [path]
    end
    @path = path
    @directory = Array.new
    @real_path = File.realpath path
    @data_root = data_root
    @types = types
    Dir.foreach(@real_path) do |file|
      rf = "%s/%s" % [@real_path, file]
      f = "%s/%s" % [path, file]
      if(File.directory? rf)
        kind = "dir"
        @directory << DirectoryItem.new(file.chomp(File.extname(file)), "/%s/%s" % [kind, f], "/%s/%s" % [kind, f], '', kind)
      elsif(types.include?(File.extname(rf).gsub(/^\./, '').downcase))
        kind = "info"
        @directory << DirectoryItem.new(file.chomp(File.extname(file)), "/%s/%s" % [kind, f], "/stream/%s" % [f], '', kind)
      end  
    end
  end
  def to_json
    return @directory.to_json
  end
  def to_html
    rtn = "<h2>%s</h2><br/>Document Root: %s<br/>Data Root: %s<br/>Real path: %s<br/><ul>" % [@path, @doc_root, @data_root, @real_path]
    @directory.each do |diritem|
      rtn << "<li>" << diritem.to_html << "</li>"
    end
    rtn << "</ul>"
    return rtn
  end
end
class Dirlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize server, doc_root='', data_root='', types=[]
    super server
    @doc_root = doc_root
    @data_root = data_root
    @media_types = types
  end
  def do_GET req, res
    status = 200
    content_type = 'text/html'
    body = '<html><body>'
    
    begin
      path = req.path.gsub(/^\/dir\/{0,1}/, '').gsub(/\/$/, '')
      dir = Directory.new(path, @doc_root, @data_root, @media_types)
      body << dir.to_html
    rescue Exception => e
      body << {"ERROR" => e.to_s}.to_json
    end
    body << "</body></html>"
    res.status = status
    res['Content-Type'] = content_type
    res.body = body
  end
  def dbug(str)
    if $DEBUG_POP
      puts "[%s] DEBUG  %s. (%s)" % [Time.now.to_s.sub(/ [\-\+][0-9]{4}$/, ''), str, self.class.name]
    end
  end
end