# I thought it was important to encapsulate this out a bit because 
# people will probably have better algorithms.

# Background: I could not find out how to escape '\' in low level IO communication, and
# ruby marshalling makes use of these characters.  So I had to take the marshalled objects
# and further sanitize.

# Currently, I'm getting an average ratio between marshalled string and final string of 1.5

module ActiveSocket
  class Protocol
  
    # Unpack: take a string and unpack it to reveal the object 
    # string of concat hexs -> array of hex values -> array of chars -> concat to string -> object via marshal
    def self.unpack(str)
      marshalled_response = ''
      hexes = str.scan(/../)
      chunk_size = 1000
      chunk = ''
      hexes.each_with_index do |c,x|    
        chunk += c.hex.chr 
        if x % chunk_size == 0
          marshalled_response += chunk
          chunk = ''
        end
      end
      marshalled_response += chunk
      begin
        obj = Marshal::load(marshalled_response)
      rescue
        ActiveSocket.log.error "failure: could not Marshal::load: #{$!}"
        obj = "failure: could not Marshal::load: #{$!}"
      end
      ActiveSocket.log.debug("unpacked: #{obj.inspect}")
      return obj
    end

    # Pack: takes an object and package it up
    # object -> string via marshal -> array of chars -> array of hex values -> string of concat hexs
    def self.pack(obj)
      begin
        ActiveSocket.log.debug("packing object #{obj.inspect}")
        str = Marshal::dump(obj)
      rescue
        ActiveSocket.log.error("Failure: could not Marshal::dump")
        str = Marshal::dump("Failure: could not Marshal::dump")
      end
      m = []
      chunk = []
      chunk_size = 1000
      index = 0
      str.each_byte do |c|
        index += 1
        h = c.to_s(16)
        h = "0" + h if h.size < 2
        chunk << h
        if index % chunk_size == 0
          m += chunk
          chunk = []
        end
      end
      m += chunk
      m.join
    end
    
  end
end