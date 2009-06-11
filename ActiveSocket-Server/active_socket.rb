module ActiveSocket
  
  #ruby modules
  require "socket"
  require "json"
  
  #active socket
  Dir.glob(File.join(File.dirname(__FILE__), '/active_socket/*.rb')).each {|f| require f }

end