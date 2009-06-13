module ActiveSocket
  require 'rubygems'
  require 'socket'
  require 'activerecord'
  require File.dirname(__FILE__) + '/connection'
  require File.dirname(__FILE__) + '/crud'
  
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
    
      #pass in the stray instance objects
      obj = response[:o]
      obj.simple_instance_variables.each do |iv|
        self.instance_variable_set(iv.to_sym, obj.instance_variable_get(iv.to_sym))
      end
      
      #return response
      return response[:r]
    end
    
    class << self # Class methods
      attr_accessor :connection
      include ClassCrud
      
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
        #copy over custom methods
        custom_instance_methods = structure[:methods][:inst]
        custom_class_methods = structure[:methods][:class]
        augment_methods(custom_instance_methods, custom_class_methods)
        
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