require 'digest/md5'
require "id3lib"

class Image
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
        return ""
      end
    end
    return "/" << img_path
  end
  def create_image kind="av", data=nil
    img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(@path)]
    if(!File.exists?(img_path))
      if("a".casecmp(kind) == 0)
        #see if we have an album image already...
        crate_img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(File.dirname(@path))]
        puts crate_img_path
        if(File.exists?(crate_img_path))
          return "/" << crate_img_path
        end
        if(data == nil)
          tag = ID3Lib::Tag.new(@path)
          if(tag.frame(:APIC))
            data = tag.frame(:APIC)[:data]
          end
        end
        img_file = File.new(img_path, "w+")
        img_file.write(data)
        img_file.close
        if(!File.exists? img_path)
          return ""
        end
      elsif("av".casecmp(kind) == 0)
        nfp = @path.gsub(/\.mp4$/, ".art[0].jpg")
        mp4art_rtn = IO.popen(['mp4art', "--extract", @path], in: :close, err: :close).read
        if(File.exists? nfp)
          FileUtils.mv nfp, img_path
          return "/" << img_path
        else
          return ""
        end
      elsif("crate".casecmp(kind) == 0)
        if(!create_crate_image(img_path))
          return ""
        end
      else
        return ""
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
        if(File.extname(file).casecmp(".mp3") == 0)
          fp = "%s/%s" % [@path, file]
          nimg_path = Image.new(@data_root, fp).create_image("a").gsub(/^\//,'')
          FileUtils.mv nimg_path, img_path
          return true
        end
      end   
    end
    return false
  end
end