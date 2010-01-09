module ActiveSocket
  class ActiveSocketServer 
    
    include Processors
    
    def initialize(port, environment = :production) 
      ActiveSocket.const_set("ENV", environment)
      @serverSocket = TCPServer.new(port) 
      @serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 ) 
      ActiveSocket.log.debug("ActiveSocket Server started on port #{port.to_s} in #{ActiveSocket::ENV} mode")
      puts "ActiveSocket Server started on port #{port.to_s} in #{ActiveSocket::ENV} mode"
      while 1
        wait_for_client
      end
    end

    private

    def wait_for_client
      ActiveSocket.log.debug("waiting for a client")
      while (@session = @serverSocket.accept) 
        help_client
        return if @session.closed?
      end
    end

    def help_client
      ActiveSocket.log.debug("helping a client")
      while 1
        wait_for_message
        return if @session.closed?
      end
    end

    def wait_for_message
      if @session.eof?
        ActiveSocket.log.debug("client disconnected :(")
        @session.close
        return
      else
        message = @session.gets
        response = process_message(message)
        @session.write(response) unless @session.closed?
      end
    end
 
  end #server
end #module