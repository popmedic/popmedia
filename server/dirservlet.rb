require 'pmlib/pmfile.rb'

class DirServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET req, res
    status = 200
    content_type = 'text/plain'
    body = ''
    
    begin
      path = req.path.gsub(/^\/dir/, '')
      prefix_path = get_prefix path
      expsd_dir = File.realpath pre_path
      dbug "Using:\n\tpath=\"%s\";\n\tpre_path=\"%s\";\n\texposed_dir=\"%s\";\n" % [path, pre_path, expsd_dir]
      
    rescue Exception => e
      body = {"ERROR" => e.to_s}.to_json
    end
    
    res.status = status
    res['Content-Type'] = content_type
    res.body = body
  end
  def get_prefix path
    rtn = false
    if(md = /^\/{0,1}(exposed\/.+?)\/(.+)/.match(path))
      rtn = md[1]
    elsif(path.split('/').count == 2)
      rtn = path
    else
      raise "(%s) Unable to match prefix of %s\nMake sure that the directory you are trying to get is under the exposed dir (preferably with symlinks)." % [self.class.name, path]
    end
    return rtn
  end
  def dbug(str)
    if $DEBUG_POP
      puts "[%s] DEBUG  %s. (%s)" % [Time.now.to_s.sub(/ [\-\+][0-9]{4}$/, ''), str, self.class.name]
    end
  end
end