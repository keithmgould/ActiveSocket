module ActiveSocket
    def log
      
      @log ||= Logger.new(APP_ROOT + "/../debug.log")
      
      # Todo: add a commented out line showing how to
      # replace this with the rails logger.
    
    end
end