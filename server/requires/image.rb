require 'digest/md5'

class Image
  def initialize data_root, path
    @data_root = data_root
    @path = File.realpath path
  end
  def image_path
    img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(@path)]
    if(!File.exists?(img_path))
      return ""
    end
    return "/" << img_path
  end
  def create_image kind="av", data=nil
    img_path = "%s/%s.jpg" % [@data_root, Digest::MD5.hexdigest(@path)]
    if(!File.exists?(img_path))
      if("a".casecmp(kind) == 0 && data != nil)
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
    ojpg_path = @path.chomp(File.extname(@path)) << "-SD.jpg"
    if(File.exists? ojpg_path)
      FileUtils.mv ojpg_path, img_path
      return true
    end 
    return false
  end
end