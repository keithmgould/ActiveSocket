module ActiveSocket

  require 'rubygems'
  require 'socket'
  require 'active_record'
  require File.dirname(__FILE__) + '/../../common/logger'
  require File.dirname(__FILE__) + '/connection'
  require File.dirname(__FILE__) + '/crud'
  ActiveSocket.log.level = Logger::DEBUG
  
  class PassAlongError < StandardError; end
  class FetchStructureError < StandardError; end
  
  class Base < ActiveRecord::Base
    self.abstract_class = true
    class_inheritable_array :columns
    self.columns = []
    include InstanceCrud
    
    self.send(:define_method, "simple_instance_variables", Object.instance_method(:instance_variables))
    
    # passes instance methods along to server, execute server-side and return results
    def pass_along_instance_method(meth_name, args)
      request = {:t => 'i', :o => self,  :m => meth_name, :a => args}
      response = self.class.communicate("passalong", self.class.to_s, request)
      
      if response
        #pass in the stray instance objects
        obj = response[:o]
        obj.simple_instance_variables.each do |iv|
          self.instance_variable_set(iv.to_sym, obj.instance_variable_get(iv.to_sym))
        end
        
        res = response[:r]
      else
        ActiveSocket.log.warn "failure in pass_along_instance_method"
        raise ActiveSocketError
        #res = false
      end
      #return response
      return res
    end
    
    class << self # Class methods
      attr_accessor :connection
      include ClassCrud
      
      def transfer_to_service(path_to_file)
        # check if file exists
        return false unless File.exists?(path_to_file)
        
        # convert file to bytestring
        file = {}
        file[:name] = File.basename(path_to_file)
        file[:body] = File.read(path_to_file)
        @connection.communicate("pushfile", class_name, file)
      end
      
      def communicate(request_type, model, request = nil)
        @connection.communicate(request_type, model, request)
      end
      
      private
      
      # this guy just passes methods along to server.
      def pass_along_class_method(meth_name, args)
        request = {:t => 'c', :m => meth_name, :a => args}
        communicate("passalong", class_name, request)
      end
      
      def active_socket_settings(args)
        #overide the AR connection with our own
        self.connection = ActiveSocket::Connection.new(class_name, args[:host], args[:port])
        fetch_structure
      end
      
      #fetch the structure of the model from the server
      def fetch_structure
        #fetch structure
        structure = communicate("structure",class_name)
        ActiveSocket.log.debug "fetched structure: #{structure.inspect}"
        
        unless structure
          ActiveSocket.log.error "failure in fetch_structure"
          raise FetchStructureError
        end
        
        #copy over custom methods
        custom_instance_methods = structure[:methods][:inst]
        custom_class_methods = structure[:methods][:class]
        augment_methods(custom_instance_methods, custom_class_methods)
        
        # Add Associations
        # Note: self.create_reflection does not work.
        # Todo: sending way too much.  just need macro and name (m)
        associations = structure[:assoc]
        associations.each_pair do |m, association|
          self.send association.macro.to_sym, m, association.options
        end
        
        #copy over column structure
        cols = structure[:cols]
        cols.each do |col|
          columns << ActiveRecord::ConnectionAdapters::Column.new(col[:name], col[:default], col[:sql_type].to_s, col[:null])
        end
      end
      
      # augment model to hand off methods found on the server ... to the server.
      # method missing does not work due to local AR hijaking method missing.
      def augment_methods(custom_instance_methods, custom_class_methods)
        #first the class methods
        custom_class_methods.each do |meth|
          class_eval "def self.#{meth}(*args); pass_along_class_method('#{meth}',args); end"
        end
        
        #then the instance methods
        custom_instance_methods.each do |meth|
          define_method(meth.to_sym) { |*args| pass_along_instance_method(meth, args) }
        end
      end
    
    end # Class Methods
  end # Base Class
end #Module