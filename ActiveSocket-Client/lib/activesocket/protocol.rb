# I thought it was important to encapsulate this out a bit because 
# people will probably have better algorithms.

# Background: I could not find out how to escape '\' in low level IO communication, and
# ruby marshalling makes use of thes characters.  So I had to take the marshalled objects
# and further sanitize.

# Currently, I'm getting an average ratio between marshalled string and final string of 1.5

module ActiveSocket
  class Protocol
  
    # Unpack: take a string and unpack it to reveal the object 
    # string of concat hexs -> array of hex values -> array of chars -> concat to string -> object via marshal
    def self.unpack(str)
      marshalled_response = ''
      hexes = str.scan(/../)
      hexes.each { |c| marshalled_response += c.hex.chr }
      begin
        obj = Marshal::load(marshalled_response)
      rescue
        Global.log.debug "failure: could not Marshal::load: #{$!}"
        obj = "failure: could not Marshal::load: #{$!}"
      end
      return obj
    end

    # Pack: takes an object and package it up
    # object -> string via marshal -> array of chars -> array of hex values -> string of concat hexs
    def self.pack(obj)
      begin
        str = Marshal::dump(obj)
      rescue
        str = Marshal::dump("Failure: could not Marshal::dump")
      end
      m = []
      str.each_byte do |c|
        h = c.to_s(16)
        h = "0" + h if h.size < 2
        m << h
      end
      m.join
    end
    
  end
end