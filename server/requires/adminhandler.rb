require 'mongrel'
require 'json'
require_relative './cfg.rb'

class AdminHandler < Mongrel::HttpHandler
  def initialize doc_root='exposed', data_root='data', apache_path=false, types=['mp4', 'mp3'], av_types=["mp4"], a_types=["mp3"]
    @doc_root = doc_root
    @data_root = data_root
    @media_types = types
    @av_types = av_types
    @a_types = a_types
    @apache_path = apache_path
    @cfg = Cfg.new $CFGFNAME
  end
  def to_json(*a)
  	rtn = {
						"doc_root" => @doc_root, 
						"data_root" => @data_root, 
						"apache_path" => @apache_path, 
						"media_types" => @media_types, 
						"av_types" => @av_types,
						"a_types" => @a_types,
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
  		kind = "unknown"
  		if(@av_types.include?(t))
  			kind = "av"
  		elsif(@a_types.include?(t))
  			kind = "a"
  		end
  		rtn <<		"<div class=\"media_type\" kind=\"" << kind << "\">" << t << "</div>"
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
  		kind = "unknown"
  		if(@av_types.include?(t))
  			kind = "av"
  		elsif(@a_types.include?(t))
  			kind = "a"
  		end
  		rtn <<		"<media_type kind=\"" << kind << "\">" << t << "</media_type>"
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
        if(path == "")
        	fmt = "html"
        end
        if($FMT != nil)
          if($FMT.include?(File.basename(path)))
            fmt = File.basename(path)
            path = path.chomp(fmt).gsub(/\/$/,'')
          end
        end
        if(path == "" && fmt == "html")
        	head["Content-Type"] = "text/html"
        	out << File.open("admin.html", "r").read
        	return
        end
        head["Content-Type"] = "text/%s" % [fmt]
        @msg = nil
        if ((md = /^add_exposed\/(.+)\/with_name\/(.+)\/{0,1}/.match(path)) != nil)
        	src = "/" << md[1]
        	if(!File.exists? src)
        		@msg = {"result" => "FAILURE", "msg" => "FILE DOES NOT EXIST: " << src}
        	else
						dst = "%s/%s" % [@doc_root, md[2]]
						@msg = {"result" => "SUCCESS", "msg" => "ln -s \"%s\" \"%s\"" % [src, dst]}
						FileUtils.ln_s(src, dst, :force => false) 
					end
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
        	nd = md[1]
        	if(File.exists?(nd))
        		if(File.directory?(nd))
							if(File.exists?(@data_root))
								FileUtils.rm @data_root
							end
							@msg = {"result" => "SUCCESS", "msg" => "ln -s \"%s\" \"%s\"" % [nd, @data_root]}
							FileUtils.ln_s nd, @data_root
						else
							@msg = {"result" => "FAILURE", "msg" => "FILE IS NOT A DIRECTORY: " << nd}
        		end
        	else 
        		@msg = {"result" => "FAILURE", "msg" => "FILE DOES NOT EXIST: " << nd}
        	end
        elsif ((md = /^set_apache_path\/(.+)\/{0,1}/.match(path)) != nil)
        	np = md[1]
        	@cfg.set('apache_path', np)
        	@cfg.save
        	@apache_path = np
        	@msg = {"result" => "SUCCESS", "msg" => (("apache_path set to: %s\n\n" <<
        																					"popmedia_server.rb must still be restarted for changes to take effect.\n" << 
        																					"Use the terminal and run:\n\t ./popmedia_server_control.rb restart.") % [np])}
        elsif ((md = /^add_media_type\/(.+)\/as_kind\/(.+)\/{0,1}/.match(path)) != nil)
        	nmt = md[1]
        	kind = md[2]
        	e = REXML::Element.new "type"
        	e.add_text nmt
        	@media_types << nmt
        	if(kind.downcase == 'av')
        		@av_types << nmt
        		e.add_attribute('kind', 'av')
        	elsif(kind.downcase == 'a')
        		@a_types << nmt
        		e.add_attribute('kind', 'a')
        	end
        	mts = @cfg.xml.root.elements['/configuration/media_types']
        	if(mts != nil)
        		mts.add(e)
        	else
        		@msg = {"result" => "FAILURE", "msg" => "UNABLE TO FIND MEDIA TYPES IN CONFIG.XML"}
        	end
        	@cfg.save
        	@msg = {"result" => "SUCCESS", "msg" => (("Added media type: %s\n\tKind: %s\n\n" <<
        																					"popmedia_server.rb must still be restarted for changes to take effect.\n" << 
        																					"Use the terminal and run:\n\t ./popmedia_server_control.rb restart.") % [nmt, kind])}
        elsif ((md = /^remove_media_type\/(.+)\/{0,1}/.match(path)) != nil)
        	mt = md[1]
        	mts = @cfg.xml.root.elements['/configuration/media_types']
        	mts.each_element do |e|
        		if(e.get_text == mt)
        			mts.delete(e)
        			@cfg.save
							if(@media_types.include?(mt))
								@media_types.delete(mt)
								if(@av_types.include?(mt))
									@av_types.delete(mt)
								elsif(@a_types.include?(mt))
									@a_types.delete(mt)
								end
								@msg = {"result" => "SUCCESS", "msg" => (("Removed media type: %s\n\n" <<
												"popmedia_server.rb must still be restarted for changes to take effect.\n" << 
												"Use the terminal and run:\n\t ./popmedia_server_control.rb restart.") % [mt])}
							else
								# @msg = {"result" => "FAILED", "msg" => ("UNABLE TO LOCATE media_type \"%s\" in media_type array." % [mt])}
							end
						end
        	end
        else
        	if(path != '')
        		@msg = {"result" => "FAILURE", "msg" => "ADMIN COMMAND FAILED: " << path}
        	end
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