require 'digest/md5'
require "id3lib"
require "mp3info"

class Image
  @@crate_img  = "/images/crate.png"
  @@afile_img  = "/images/afile.png"
  @@avfile_img = "/images/avfile.png"
  def initialize data_root, path
    @data_root = data_root
    @path = File.realpath path
  end
  def image_path
    img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(@path)]
    if(!File.exists?(img_path))
      if(!create_crate_image(img_path))
        if(File.extname(@path).downcase == '.mp3')
          return create_image "a"
        end
        return @@crate_img
      end
    end
    return "/" << img_path
  end
  def create_image kind="av", data=nil, default_img=false
    img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(@path)]
    if(!File.exists?(img_path))
      if("a".casecmp(kind) == 0)
        #see if we have an album image already...
        #crate_img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(File.dirname(@path))]
        #if(File.exists?(crate_img_path))
        #  return "/" << crate_img_path
        #end
        if(data == nil)
          #Mp3Info.open(@path) do |mp3|
          #	pic = mp3.tag2.pictures
          #	if(pic != nil)
					#		if(pic.length > 1)
					#			data = pic[0][1];
					#		else
								otag = ID3Lib::Tag.new(@path)
								if(otag.frame(:APIC))
									data = otag.frame(:APIC)[:data]
								end
					#		end
					#	end
          #end
        end
        if(data != nil)
        	File.binwrite(img_path, data)
        	return "/" << img_path
				end
        if(!File.exists? img_path)
        	if(default_img != false)
          	return default_img
          end
          return @@afile_img
        end
      elsif("av".casecmp(kind) == 0)
        nfp = @path.gsub(/\.mp4$/, ".art[0].jpg")
        io = IO.popen(['mp4art', "--extract", @path], in: :close, err: :close)
        mp4art_rtn = io.read
        io.close()
        if(File.exists? nfp)
          FileUtils.mv nfp, img_path
          return "/" << img_path
        else
        	if(default_img != false)
          	return default_img
          end
          return @@avfile_img
        end
      elsif("crate".casecmp(kind) == 0)
        if(!create_crate_image(img_path))
          if(default_img != false)
          	return default_img
          end
          return @@crate_img
        end
      else
      	if(default_img != false)
					return default_img
				end
        return @@crate_img
      end
    end
    return "/" << img_path
  end
  def create_crate_image(img_path)
    #if we have a jpeg for the file (old popmedic...)
    ojpg_path = @path.chomp(File.extname(@path)) << "-SD.jpg"
    if(File.exists? ojpg_path)
      FileUtils.cp ojpg_path, img_path
      return true
    end
    #now lets see if we have a album...
    if(File.directory? @path)
      Dir.foreach(@path) do |file|
        if(File.extname(file).casecmp(".mp3") == 0 && file[0] != ".")
          fp = "%s/%s" % [@path, file]
          nimg_path = Image.new(@data_root, fp).create_image("a", nil, @@crate_img).gsub(/^\//,'')
          if(nimg_path == @@crate_img.gsub(/^\//, ''))
          	return false
          else
          	FileUtils.cp nimg_path, img_path
          	return true
          end
        end
      end   
    end
    return false
  end
end