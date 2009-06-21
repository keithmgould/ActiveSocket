module ActiveSocket
  
  # Directory receiving files from Front-End.
  # modify as needed:
  DROPZONE = File.dirname(__FILE__)
  
  #ruby libraries
  require "rubygems"
  require "socket"
  require "json"
  
  #active socket
  require File.dirname(__FILE__) + '/../common/logger'
  require File.dirname(__FILE__) + '/../common/protocol'
  require File.dirname(__FILE__) + '/processors'
  require File.dirname(__FILE__) + '/server'

end