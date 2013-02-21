require "rexml/document"

class Cfg
	def initialize cfgpath
		@cfgpath = cfgpath
		f = File.new @cfgpath
		@xml = REXML::Document.new f
		if(@xml == nil)
			raise "UNABLE TO OPEN \"%s\" (%s)" % [@cfgpath, self.class.name]
		end
		f.close
	end
	def xml
		return @xml
	end
	def get(key, dflt='')
		key = "/configuration/" << key
    rtn = false
    e = @xml.root.elements[key]
    if(e)
      rtn = e.text
    end
    if(!rtn) 
      rtn = dflt
    end
    return rtn
  end 
  def set(key, value)
  	key = "/configuration/" << key
    rtn = false
    e = @xml.root.elements[key]
    if(e)
    	e.text= value
    	rtn = true
    end
    return rtn 
  end
  def save
  	f = File.open @cfgpath, "w"
  	@xml.write f
  	f.close
  end
end