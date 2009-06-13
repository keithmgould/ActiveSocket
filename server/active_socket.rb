module ActiveSocket
  
  #ruby libraries
  require "rubygems"
  require "socket"
  require "json"
  
  #active socket
  require File.dirname(__FILE__) + '/../common/protocol'
  require File.dirname(__FILE__) + '/processors'
  require File.dirname(__FILE__) + '/server'

end