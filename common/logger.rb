module ActiveSocket
    def log
      
      @log ||= Logger.new(File.dirname(__FILE__) + "/../debug.log")
      
      # Replace the above line with the following to use Rails logging:
      # @log ||= Rails.logger
    
    end
    module_function :log
end