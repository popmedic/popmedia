require "rubygems"
require "id3lib"
require 'cgi'

class PMFile
  def initialize(pth, realdir=0, linkdir=0)
    @properties = Hash.new
    @linkDir = 0
    @realDir = 0
    setProperty "type", "PMFile"
    setPath pth
    if(realdir != 0 && linkdir != 0)
      setDirLink realdir, linkdir
    end
  end
  def setProperty name, value
    @properties[name] = value
  end
  def getProperty name
    prop = @properties[name]
    if(!prop)
      raise "(%s) Property \"%s\" is not set." % [type, name]
    end
    dbug "(%s) Set: \"%s\" To: "
    return prop
  end
  def setType typ
    setProperty "type", typ
  end
  def type
    return getProperty type
  end
  def path
    return getProperty 'path' 
  end
  def setPath pth
    if(!File.exists? pth)
      raise "(%s) File \"%s\" does not exist." % [type, pth]
    end
    setProperty 'path', pth
  end
  def setDirLink realdir, linkdir
    if(!path)
      raise "(%s) First set a path to the file." % [type]
    end
    if(!File.exists? realdir)
      raise "(%s) Directory \"%s\" does not exist." % [type, realdir]
    end
    if(!File.directory? realdir)
      raise "(%s) \"%s\" is not a directory." % [type,realdir]
    end
    if(!File.exists? linkdir)
      raise "(%s) Directory \"%s\" does not exist." % [type, linkdir]
    end
    if(!File.directory? linkdir)
      raise "(%s) \"%s\" is not a directory." % [type, linkdir]
    end
    @realDir = realdir
    @linkDir = linkdir
    @properties['exposed_path'] = path.gsub(/^#{realdir}/, linkdir)
  end
  def exposedPath
    if(@realDir == 0 || @linkDir == 0)
      raise "(%s) You must first create a directory link (%s.setDirLink \"/some/dir\", \"/some/link\")." % [type, expsd, self.class.name]
    end
    return getProperty 'exposed_path'
  end
  def to_xml
    rtn = "<%s " % self.class.name
    @properties.each do |key, value|
      if(value)
        rtn << key << "=\"" << CGI::escapeHTML(value) << "\" "
      end
    end
    rtn << "/>"
    return rtn
  end
  def to_json
    rtn = "{"
    @properties.each do |key, value|
      if(value)
        rtn << "\"%s\" => \"%s\"," % [key, value]
      end
    end
    rtn.gsub! /\,$/, ''
    rtn << "}"
    return rtn
  end
end

class PMMusicFile < PMFile
  def initialize(pth, realdir=0, linkdir=0)
    super(pth, realdir, linkdir)
    setType "PMMusicFile"
    tag = ID3Lib::Tag.new(pth)
    if(tag.title)
      rtn.setTitle tag.title.encode
    end
    if(tag.album)
      rtn.album tag.album.encode
    end
    if(tag.artist) 
      rtn.artist tag.artist.encode
    end
    if(tag.comment) 
      rtn.comment tag.comment.encode
    end
    if(tag.track)
      rtn.track tag.track.encode
    end
    if(tag.time)
      rtn.time tag.time.encode
    end
    if(tag.year) 
      rtn.year tag.year.encode
    end
    if(tag.publisher)
      rtn.publisher tag.publisher.encode
    end
    if(tag.genre)
      rtn.setGenre tag.genre.encode
    end
    def title
      return getProperty 'title'
    end
    def setTitle ttl
      setProperty 'title', ttl
    end
    def image
      return getProperty 'image'
    end
    def setImage img
      setProperty 'image', img
    end
    def header1
      return getProperty 'header1'
    end
    def setHeader1 hdr
      setProperty 'header1', hdr
    end
    def header2
      return getProperty 'header2'
    end
    def setHeader2 hdr
      setProperty 'header2', hdr
    end
    def description
      return getProperty 'description'
    end
    def setDescription desc
      setProperty 'description', desc
    end
    def footer1
      return getProperty 'footer1'
    end
    def setFooter1 ftr
      setProperty 'footer1', ftr
    end  
    def footer2
      return getProperty 'footer2'
    end
    def setFooter2 ftr
      setProperty 'footer2', ftr
    end
    def footer3
      return getProperty 'footer3'
    end
    def setFooter3 ftr
      setProperty 'footer3', ftr
    end  
    def footer4
      return getProperty 'footer4'
    end
    def setFooter4 ftr
      setProperty 'footer4', ftr
    end
    def base1
      return getProperty 'base1'
    end
    def setBase1 ftr
      setProperty 'base1', ftr
    end  
    def base2
      return getProperty 'base2'
    end
    def setBase2 ftr
      setProperty 'base2', ftr
    end
    return rtn
  end
end
  
#musicfile = PMMusicFileInfo.new "/Volumes/MusicPop/Gotye/Making Mirrors 2011/01 - Making Mirrors.mp3"
#puts musicfile.to_json