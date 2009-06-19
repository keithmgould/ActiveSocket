module ActiveSocket
    def log
      
      @log ||= Logger.new(File.dirname(__FILE__) + "/../debug.log")
      
      # Todo: add a commented out line showing how to
      # replace this with the rails logger.
    
    end
    module_function :log
end