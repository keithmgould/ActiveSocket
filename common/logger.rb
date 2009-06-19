module ActiveSocket
    def log
      
      @log ||= Logger.new(APP_ROOT + "/../client_debug.log")
      
      # Todo: add a commented out line showing how to
      # replace this with the rails logger.
    
    end
end

# Should this be defined in active_socket.rb?
ActiveSocket.log.level = Logger::DEBUG