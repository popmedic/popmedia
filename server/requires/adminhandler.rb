require 'mongrel'
require 'json'

class AdminHandler < Mongrel::HttpHandler
  def initialize doc_root='exposed', data_root='data', apache_path=false, types=['mp4', 'mp3']
    @doc_root = doc_root
    @data_root = data_root
    @media_types = types
    @apache_path = apache_path
  end
  def to_json(*a)
  	rtn = {
						"doc_root" => @doc_root, 
						"data_root" => @data_root, 
						"apache_path" => @apache_path, 
						"media_types" => @media_types, 
						"doc_path" => File.absolute_path(@doc_root),
						"data_path" => File.absolute_path(File.readlink(File.absolute_path(@data_root)))
					}  					
  	exposed_dirs = []
  	Dir.foreach(File.absolute_path(@doc_root)) do |file|
  		if File.symlink?("%s/%s" % [File.absolute_path(@doc_root).gsub(/\/$/,''), file])
  			exposed_dirs << {
  												"name" => file, 
  												"path" => File.readlink("%s/%s" % 
  																	[File.absolute_path(@doc_root).gsub(/\/$/,''), file])
  																	
  											}
  		end
  	end
  	rtn["exposed"] = exposed_dirs
  	if @msg != nil
  		rtn["msg"] = @msg
  	end
  	return rtn.to_json(*a)
  end
  def to_html
  	rtn = "<div class=\"admin\">"
  	if @msg != nil
  		rtn << 	"<div class=\"" << @msg["result"] << "\">" << @msg["msg"] << "</div>"
  	end
  	rtn <<	 "<div class=\"doc_root\">"    << @doc_root    << "</div>"    <<
  						"<div class=\"data_root\">"   << @data_root   << "</div>"   <<
  						"<div class=\"apache_path\">" << @apache_path << "</div>" <<
  						"<div class=\"doc_path\">" << File.absolute_path(@doc_root) << "</div>" <<
  						"<div class=\"data_path\">" << File.absolute_path(File.readlink(File.absolute_path(@data_root))) << "</div>" <<
  						"<div class=\"media_types\">" 
  	@media_types.each do |t|
  		rtn <<		"<div class=\"media_type\">" << t << "</div>"
  	end					
  	rtn <<		"</div>"
  	rtn <<	 	"<div class=\"exposed\">"
  	Dir.foreach(File.absolute_path(@doc_root)) do |file|
  		if File.symlink?("%s/%s" % [File.absolute_path(@doc_root).gsub(/\/$/,''), file])
  			rtn << 	"<div class=\"crate\" path=\"" << "%s/%s" % [File.absolute_path(@doc_root).gsub(/\/$/,''), file] << "\">" << file << "</div>"
  		end
  	end
  	rtn <<		"</div>"
  	rtn <<	"</div>"
  end
  def to_xml
  	rtn = 	"<admin>"
  	if @msg != nil
  		rtn << 	"<msg result=\"" << @msg["result"] << "\">" << @msg["msg"] << "</msg>"
  	end
  	rtn << 		"<doc_root>"    << @doc_root    << "</doc_root>"    <<
  						"<data_root>"   << @data_root   << "</data_root>"   <<
  						"<apache_path>" << @apache_path << "</apache_path>" << 
  						"<doc_path>" << File.absolute_path(@doc_root) << "</doc_path>" <<
  						"<data_path>" << File.absolute_path(File.readlink(File.absolute_path(@data_root))) << "</data_path>" <<
  						"<media_types>"
  	@media_types.each do |t|
  		rtn <<		"<media_type>" << t << "</media_type>"
  	end
  	rtn << 		"</media_types>"
  	rtn <<	 	"<exposed>"
  	Dir.foreach(File.absolute_path(@doc_root)) do |file|
  		if File.symlink?("%s/%s" % [File.absolute_path(@doc_root).gsub(/\/$/,''), file])
  			rtn << 	"<crate path=\"" << "%s/%s" % [File.absolute_path(@doc_root).gsub(/\/$/,''), file] << "\">" << file << "</crate>"
  		end
  	end
  	rtn <<		"</exposed>"
  	rtn <<	"</admin>"
  	return rtn
  end
  def process(req, res)
    res.start(200) do |head,out|
      begin
    		puts ("incoming: %s" % req.params["REQUEST_PATH"])
        path = URI.unescape(req.params["REQUEST_PATH"]).gsub(/^\/admin\/{0,1}/, '').gsub(/\/$/, '')
        fmt = "json"
        if($FMT != nil)
          if($FMT.include?(File.basename(path)))
            fmt = File.basename(path)
            cfmt = "/%s" % [fmt]
            path = path.chomp(cfmt)
          end
        end
        head["Content-Type"] = "text/%s" % [fmt]
        @msg = nil
        if ((md = /^add_exposed\/(.+)\/with_name\/(.+)\/{0,1}/.match(path)) != nil)
        	src = "/" << md[1]
        	dst = "%s/%s" % [@doc_root, md[2]]
        	@msg = {"result" => "SUCCESS", "msg" => "ln -s \"%s\" \"%s\"" % [src, dst]}
        	FileUtils.ln_s(src, dst, :force => false) 
        elsif ((md = /^remove_exposed\/(.+)\/{0,1}/.match(path)) != nil)
        	rm = md[1]
        	if(/^#{@doc_root}/.match(rm) == nil)
        		@msg = {"result" => "FAILURE", "msg" => "FILE IS NOT IN EXPOSED DIRECTORY: " << rm}
        	elsif(!File.exists? rm)
        		@msg = {"result" => "FAILURE", "msg" => "FILE DOES NOT EXIST: " << rm}
        	elsif(!File.symlink? rm)
        		@msg = {"result" => "FAILURE", "msg" => "FILE MUST ME A SYMLINK: " << rm}
        	else
        		@msg = {"result" => "SUCCESS", "msg" => "rm \"%s\"" % rm}
        		FileUtils.rm rm
        	end
        elsif ((md = /^set_data_path\/(.+)\/{0,1}/.match(path)) != nil)
        	
        end
        if fmt == 'json'
        	out << to_json
        elsif(fmt == "html")
          out << to_html
        elsif(fmt == "xml")
          out << to_xml
        end
      rescue Exception => e
        out << {"ERROR" => e.to_s}.to_json
      end
    end
  end
end