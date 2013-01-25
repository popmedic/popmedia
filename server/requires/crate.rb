require 'mongrel'
require 'json'
require 'cgi'
require './requires/image.rb'

class CrateItem
  def initialize(name, info, href, stream, image, kind)
    @hash =  {
                "name" => name, 
                "info" => info, 
                "href" => href,
                "stream" => stream, 
                "image" => image, 
                "kind" => kind
              }
  end
  def to_json(*a)
    return @hash.to_json(*a)
  end
  def to_xml
    rtn = "<item>"
    @hash.keys.each do |key|
      rtn << "<%s>%s</%s>" % [key, CGI.escapeHTML(@hash[key]), key]
    end
    rtn << "</item>"
    return rtn
  end
  def to_html
    rtn = String.new
    rtn << "<img height=\"64px\" src=\"%s\"/>" % [@hash["image"]]
    if(@hash['kind'] == 'info')
      rtn << "<a href=\"%s\">%s</a> (<a href=\"%s\">%s</a>)" % [@hash["stream"],
                                                                @hash["name"], 
                                                                @hash["info"], 
                                                                @hash["kind"]]
    elsif(@hash['kind'] == 'crate')
      rtn << "<a href=\"%s\">%s</a> (<a href=\"%s\">%s</a>)" % [@hash["info"],
                                                                @hash["name"], 
                                                                @hash["info"], 
                                                                @hash["kind"]]
    else
      rtn << "<a href=\"%s\">%s</a> (<a href=\"%s\">%s</a>)" % [@hash['href'],
                                                                @hash["name"], 
                                                                @hash["info"], 
                                                                @hash["kind"]]
    end
    return rtn
  end
end
class Crate
  attr_reader :crate
  attr_reader :doc_root
  attr_reader :data_root
  attr_reader :types
  attr_reader :apache_path

  def initialize(path, doc_root='', data_root='', apache_path=false, types=[])
    @doc_root = doc_root
    @crate = Array.new
    @data_root = data_root
    @types = types
    @apache_path = apache_path
    if(!path)
      return
    end
    if(/^#{@doc_root}\//.match("%s/" % path) == nil)
      raise "%s: NOT AN EXPOSED DIRECTORY!" % [path]
    end
    @path = path
    @real_path = File.realpath path
    Dir.foreach(@real_path) do |file|
      if(/^\./.match(file) == nil)
        rf = "%s/%s" % [@real_path, file]
        f = "%s/%s" % [path, file]
        if(File.directory? rf)
          kind = "crate"
          img_path = Image.new(@data_root, rf).create_image kind
          @crate << CrateItem.new(
                                    file.chomp(File.extname(file)), #name
                                    URI.escape("/%s/%s" % [kind, f]), #info
                                    URI.escape("/%s/%s" % [@doc_root, f]), #href
                                    '', #stream
                                    URI.escape(img_path), #image
                                    kind #kind
                                  )
        elsif(types.include?(File.extname(rf).gsub(/^\./, '').downcase))
          kind = "info"
          strm = "/stream/%s" % [f] #stream
          if(@apache_path)
            @apache_path.gsub!(/\/$/,'')
            strm = "%s/%s" % [@apache_path, f]
          end
          img_path = Image.new(@data_root, rf).image_path
          @crate << CrateItem.new(
                                        file.chomp(File.extname(file)), 
                                        URI.escape("/%s/%s" % [kind, f]), 
                                        URI.escape("/%s" % [f]), 
                                        URI.escape(strm),
                                        URI.escape(img_path), 
                                        kind
                                      )
        end  
      end
    end
  end
  def Crate::dirwalk(dir, qry, rtn)
    unless dir[0,1] == "."	
  	  if File.directory?(dir)
  	    Dir.foreach(dir) do |f|
  	      do_search = rtn.types.include?(File.extname(f).gsub(/^\./, '').downcase)
  		    kind = "info"
  		    if File.directory?(dir + "/" + f) and f[0,1] != "."
  		      Crate.dirwalk(dir + "/" + f, qry, rtn)
  		      kind = "crate"
  		      do_search = true
  		    end
  		    if(do_search)
    		    if qry =~ f
    			    fl = dir + "/" + f
    			    img_path = Image.new(rtn.data_root, File.realpath(fl)).image_path
              strm = "/stream/%s" % [fl] #stream
              if(rtn.apache_path)
                ap = rtn.apache_path.gsub(/\/$/,'')
                strm = "%s/%s" % [ap, fl]
              end
              rtn.crate << CrateItem.new(
                                        f.chomp(File.extname(f)), 
                                        URI.escape("/%s/%s" % [kind, fl]), 
                                        URI.escape("/%s" % [fl]), 
                                        URI.escape(strm),
                                        URI.escape(img_path), 
                                        kind
                                      ) 
    		    end
  		    end
	      end
  	  end
    end
  end
  def Crate::search(search_str, doc_root='', data_root='', apache_path=false, types=[])
    rtn = Crate.new(false, doc_root, data_root, apache_path, types)
    Crate.dirwalk(doc_root, /#{search_str}/i, rtn) 
    return rtn
  end
  def to_json(*a)
    return @crate.to_json(*a)
  end
  def to_xml
    rtn = "<crate>"
    @crate.each do |crateitem|
      rtn << crateitem.to_xml
    end
    rtn << "</crate>"
    return rtn
  end 
  def to_html
    rtn = "<html><body><h2>%s</h2><ul>" % [@path]
    @crate.each do |crateitem|
      rtn << "<li>" << crateitem.to_html << "</li>"
    end
    rtn << "</ul></body></html>"
    return rtn
  end
end