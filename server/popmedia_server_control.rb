#!/usr/local/bin/ruby

require 'daemons'

rf = File.realpath(__FILE__)
path = rf.gsub(File.basename(rf), 'popmedia_server.rb')

Daemons.run(path)
