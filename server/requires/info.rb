require "rubygems"
require "id3lib"
require 'mongrel'
require 'fileutils'
require 'json'

class Info
  def initialize path, doc_root='', data_root='', apache_path=false, types=[], av_types=[], a_types=[]
    @doc_root = doc_root
    if(/^#{@doc_root}\//.match("%s/" % path) == nil)
      raise "%s: NOT IN AN EXPOSED DIRECTORY!" % [path]
    end
    @path = path
    @hash = Hash.new
    @real_path = File.realpath path
    @data_root = data_root
    @types = types
    @av_types = av_types
    @a_types = a_types
    @apache_path = apache_path
    if(@apache_path)
      @hash['href'] = "%s/%s" % [@apache_path, @path]
    else
      @hash['href'] = "/stream/%s" % [@path]
    end
    ext = File.extname(path).gsub(/^\./, '').downcase
    if(@types.include?(ext))
      if(@av_types.include?(ext))
        @hash['type'] = 'av'
        av_info
      elsif(@a_types.include?(ext))
        @hash['type'] = 'a'
        audio_info
      else
        raise "UNKNOWN TYPE(2): %s" % ext
      end
    else
      raise "UNKNOWN TYPE: %s" % ext
    end
  end
  def av_info
    mp4info_rtn = IO.popen(["mp4info", @real_path], in: :close, err: :close).read
    mp4info_rtn.split(/\n/).each do |line|
      if(/^ /.match(line) != nil)
        nv = line.split(/\:/, 2)
        if(nv.count == 2)
          @hash[nv[0].strip().gsub(/ /, '_')] = nv[1].strip()
        end
      end
    end
    if(@hash["Cover_Art_pieces"])
      if(@hash["Cover_Art_pieces"].to_i > 0)
        @hash["image"] = Image.new(@data_root, @real_path).create_image('av')
      end
    end
  end
  def audio_info
    tag = ID3Lib::Tag.new(@real_path)
    if(tag.title)
      @hash['title'] = tag.title.encode
    end
    if(tag.album)
      @hash['album'] = tag.album.encode
    end
    if(tag.artist) 
      @hash['artist'] = tag.artist.encode
    end
    if(tag.comment) 
      @hash['comment'] = tag.comment.encode
    end
    if(tag.track)
      @hash['track'] = tag.track.encode
    end
    if(tag.time)
      @hash['time'] = tag.time.encode
    end
    if(tag.year) 
      @hash['year'] = tag.year.encode
    end
    if(tag.publisher)
      @hash['publisher'] = tag.publisher.encode
    end
    if(tag.genre)
      @hash['genre'] = tag.genre.encode
    end
    if(tag.frame(:APIC))
      @hash["image"] = Image.new(@data_root, @real_path).create_image('a', tag.frame(:APIC)[:data])
    end
  end
  def to_html
    rtn = "<html><body><h2><a href=\"%s\">%s</a></h2><table><tr><td width=\"20%%\"><img width=\"240px\" src=\"%s\"/></td><td><ul>" % [@hash['href'], File.basename(@path).chomp(File.extname(@path)), @hash['image']]
    @hash.keys.each do |key|
      rtn << "<li><b>%s</b>: %s</li>" % [key, @hash[key]]
    end
    rtn << "</ul></td></tr></table></body></html>"
    return rtn
  end
  def to_json(*a)
    return @hash.to_json
  end
  def to_xml
    rtn = "<info>"
    @hash.keys.each do |key|
      rtn << "<%s>%s</%s>" % [key, CGI.escapeHTML(@hash[key]), key]
    end
    rtn << "</info>"
    return rtn
  end
  
  def Info::image_path(path, data_root)
    img_path = "%s/%s.jpg" % [data_root, Digest::MD5.hexdigest(path)]
    if(File.exists?(img_path))
      return img_path
    end
    return false
  end
end