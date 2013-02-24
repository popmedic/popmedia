require 'mongrel'
require 'json'
require 'zip/zip'

class DownloadHandler < Mongrel::HttpHandler
  def initialize doc_root='exposed', data_root='data', apache_path=false, types=['mp4', 'mp3'], av_types=['mp4'], a_types=['mp3']
    @doc_root = doc_root
    @data_root = data_root
    @media_types = types
    @apache_path = apache_path
    @av_types = av_types
    @a_types = a_types
  end
  def process(req, res)
    res.start(200) do |head,out|
      begin
        path = URI.unescape(req.params["REQUEST_PATH"]).gsub(/^\/download\/{0,1}/, '').gsub(/\/$/, '')
        if(/^#{@doc_root}\//.match("%s/" % path) == nil)
		  raise "%s: NOT IN AN EXPOSED DIRECTORY!" % [path]
		end
        is_album = Crate.is_album?(path)
        if(!File.exists?(path))
        	raise "FILE \"%s\" DOES NOT EXIST" % [path]
        elsif(File.directory?(path) && !is_album)
        	raise "FILE \"%s\" IS NOT AN ALBUM CRATE.\nFile to download must be a FILE of type [%s] or a Album crate." % [path, @media_types.join(', ')]
        end
        ext = File.extname(path).gsub(/^\./, '')
        if(!@media_types.include?(ext.downcase) && !is_album)
          raise "ONLY ALLOWED TO DOWNLOAD [%s] FILES." % [@media_types.join(', ')]
        end
        if is_album
        	znf = "%s/%s.zip" % [@data_root, File.basename(path)]
        	Zip::ZipFile.open(znf, Zip::ZipFile::CREATE) do |zf|
        		Dir.foreach(path) do |fn|
        			if(@a_types.include?(File.extname(fn).gsub(/^\./,'')))
        				begin
        					# puts "add %s" % path + '/' + fn
        					zf.add(fn, path + '/' + fn)
        				rescue => e
        					puts "ZIPPING ERROR: %s" % e.to_s
        				end
        			end
        		end
        	end
        	head["Content-Type"] =  "application/zip"
        	head["Content-length"] = File.size(znf)
        	head["Content-Encoding"] = "zip"
        	out << File.new(znf).read
        	FileUtils.rm znf, :force => true
        #	head["Content-Type"] = "text/html"
        #	out << '<html><body style="font-size:32px;font-family:Arial, Helvetica, sans-serif;">' << znf << '</body></html>'
        else
        	fs = File.size(path)
					if(fs > 30000000)
						raise "FILE \"%s\" IS TO LARGE: %i > 30000000" % [path, fs]
					end
        	head["Content-Type"] =  "application/force-download"
        	head["Content-length"] = fs
        	out << File.new(path).read
        end
       # head["Content-Disposition"] = "attachment; filename=\"#{File.realpath(path)}\""
       # head["Content-length"] = File.size(path)
       # out << 'head["Content-Type"] =  "application/force-download"'
			 # out << 'head["Content-Disposition"] = "attachment; filename=\"#{' << File.realpath(path) << '}\""' 
			 # out << "head[\"Content-length\"] = #{File.size(path)}"
       # head["Content-Type"] = "text/%s" % [fmt]
       # crate = Crate.new(path, @doc_root, @data_root, @apache_path, @media_types)
       # if(fmt == "html")
       #   out << crate.to_html
       # elsif(fmt == "json")
       #   out << crate.to_json
       # elsif(fmt == "xml")
       #   out << crate.to_xml
       # end
      rescue Exception => e
        head["Content-Type"] = "text/json"
        out << {"ERROR" => e.to_s}.to_json
      end
    end
  end
end