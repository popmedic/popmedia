#!/usr/local/bin/ruby

require 'fileutils'

def usage
	puts " USAGE: deploy.rb \"/path/to/deploy/to/\""
end
	
if ARGV.length != 1
	usage
	exit
end

dpath = ARGV[0].gsub(/\/$/,'') << '/'
if !File.exists?(dpath)
	usage
	puts "   ERROR: DOES NOT EXIST: \"%s\"" % dpath
	exit
end

if !File.directory?(dpath)
	usage
	puts "   ERROR: NOT A DIRECTORY: \"%s\"" % dpath
	exit
end

puts "cp 'popmedia_server.rb', "+ dpath
FileUtils.cp 'popmedia_server.rb', dpath
puts "cp 'popmedia_server_control.rb', "+ dpath
FileUtils.cp 'popmedia_server_control.rb', dpath
#puts "cp 'config.xml', "+ dpath
#FileUtils.cp 'config.xml', dpath
puts "cp 'index.html', "+ dpath
FileUtils.cp 'index.html', dpath
puts "cp 'admin.html', "+ dpath
FileUtils.cp 'admin.html', dpath
puts "rm -r " + dpath + "requires"
FileUtils.rm_r dpath + 'requires', :force => true
puts "cp -r 'requires', "+ dpath
FileUtils.cp_r 'requires', dpath 
puts "rm -r " + dpath + 'jscripts'
FileUtils.rm_r dpath + 'jscripts', :force => true
puts "cp -r 'jscripts', "+ dpath
FileUtils.cp_r 'jscripts', dpath 
puts "rm -r " + dpath + 'images'
FileUtils.rm_r dpath + 'images', :force => true
puts "cp -r 'images', "+ dpath
FileUtils.cp_r 'images', dpath

#set up the data directory
if File.exists?(dpath+'data')
	#if !File.symlink?(dpath+'data')
	#	puts "mv "+dpath+"data, "+dpath+'_data'
	#	FileUtils.mv dpath+'data', dpath+'_data'
	#	puts "ln -s "+dpath+'_data'+", "+dpath+'data'
	#	FileUtils.ln_s dpath+'_data', dpath+'data'
	#end
else
	#if !File.exists?(dpath+'_data')
	#	puts "mkdir " + dpath+'_data'
	#	FileUtils.mkpath dpath+'_data'
	#	puts "ln -s "+dpath+'_data'+", "+dpath+'data'
	#	FileUtils.ln_s dpath+'_data', dpath+'data'
	#else
	#	puts "ln -s "+dpath+'_data'+", "+dpath+'data'
	#	FileUtils.ln_s dpath+'_data', dpath+'data'
	#end
end

#set up the exposed direcory
if !File.exists?(dpath+'exposed')
	puts "mkdir " + dpath+'exposed'
	FileUtils.mkpath dpath+'exposed'
end 