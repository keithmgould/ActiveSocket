module ActiveSocket
  require 'lib/protocol'
  
  # The ActiveSocket Connection class serves a few functions:
  # 1) It overrides the ActiveRecord Connection class and via method missing
  #    passes requests over to the server.  We want to use method_missing as little
  #    as possible because methods which call Base.connection tend to use it frequently 
  #    as it is (of course) assumed to be local.  Thus we try to override basic CRUD
  #    (and client-side Base.connection) with our own methods in ActiveSocket::Base
  #    
  # 2) It houses the communicate method passing requests to the server
  
  class Connection
    
    def initialize(model, host, port)
      @model = model
      @host = host
      @port = port
    end

    def method_missing(attempted_method, *arguments)
      request = {:attempted => attempted_method, :args => arguments}
      communicate("connection",@model,request) 
    end
  
    def communicate(request_type, model, request = nil)
      begin
        session = TCPSocket.open(@host, @port)
      rescue
        Rails.logger.debug "failure: could not open connection to server: #{$!}"
        return "failure: could not open connection to server: #{$!}"
      end
    
      if request
        packed_request = Protocol.pack(request)
        message ="#{request_type}:#{model}:#{packed_request}\n"
      else
        message = "#{request_type}:#{model}\n"
      end
      #puts "sending #{message}"
      session.write(message)
      #puts "waiting for response..."
      if session.eof?
        response = "we got disconnected :("
      else
        raw_response = session.gets
        session.close
        response = Protocol.unpack(raw_response) 
      end
      return response
    end
    
  end #Connection Class
end # Module