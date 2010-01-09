module ActiveSocket
    def log
      unless @log
        @log = Logger.new(File.dirname(__FILE__) + "/../log.log")
        @log.level = (ActiveSocket.const_defined?("ENV") && ActiveSocket::ENV == :development) ? Logger::DEBUG : Logger::WARN
      end
      @log
    end
    module_function :log
end