module ActiveSocket
  module Processors
    
      private 
      
      def process_message(message)
        begin
          command, model, body = message.chomp.split(":")
          ActiveSocket.log.debug "processing: #{command} on #{model}"
          case command
            when 'exit'
              exit_server 
            when 'passalong'
              response = passalong_object(model, body)
            when 'connection'
              response = process_connection(model, body) 
            when 'structure'
              response = reveal_structure(model)
            when 'create'
              response = create_object(model, body)
            when 'read'
              response = read_object(model,body)
            when 'update'
              response = update_object(model,body)
            when 'delete' 
              response = delete_object(model,body) 
            when 'destroy'
              response = destroy_object(model,body)
            when 'pushfile'
              response = push_file(model,body)
            else
              raise
          end
        rescue
         # Note: we should never need to get rescued.
         # If we do, fortify offending method below.
         ActiveSocket.log.warn "failed in process_message: #{$!}"
         response = Protocol.pack("failure: unable to process message: #{$!}")
        end
        return (response + "\n")
      end
    
      def push_file(model,body)
        ActiveSocket.log.debug  "in push_file"
        file = Protocol.unpack(body)
        drop_path = DROPZONE + "/#{file[:name]}"
        File.open(drop_path, 'w') { |f| f.write(file[:body])}
        return Protocol.pack(true)
      end
    
      def exit_server
        ActiveSocket.log.debug "Death Warrant!"
        exit
      end
    
      def create_object(model, body)
        obj = Protocol.unpack(body)
        if model.to_s == obj.class.to_s
          success = obj.save
          if success
            response = {:success => true, :obj => obj}
          else
            response = {:success => false}
          end
        else
          response = {:success => false}
        end
        return Protocol.pack(response)
      end   
     
      def read_object(model,body)
        request = Protocol.unpack(body)
        response = model.classify.constantize.send(request[:m],*request[:a]) 
        return Protocol.pack(response)
      end
     
      def update_object(model,body)
        ActiveSocket.log.debug "in process update"
        args = Protocol.unpack(body)
        obj = model.classify.constantize.find(args[:id])
        if obj
          args[:a].each_pair do |attrib,val|
            obj.send("#{attrib}=",val)
          end
          response = obj.save
        else
          response = false
        end
        return Protocol.pack(response)
      end
    
      def destroy_object(model,body)
        ActiveSocket.log.debug "in process destroy"
        obj_id = Protocol.unpack(body) if body
        obj = model.classify.constantize.find(obj_id)
        if obj
          response = obj.destroy
        else
          response = false
        end 
        return Protocol.pack(response)      
      end
    
      def delete_object(model,body = nil)
        ActiveSocket.log.debug "in process delete"
        conditions = Protocol.unpack(body) if body
      
        response = model.classify.constantize.delete_all(conditions)
        return Protocol.pack(response)
      end
      
      # passalong_object is a method used to pass along a method (and arguments)
      # from client to server.  Passalong processes the request and returns the 
      # results
      def passalong_object(model,body)
        ActiveSocket.log.debug "in passalong"
        request = Protocol.unpack(body)
        
        #if type is a class
        if request[:t] == "c"
          response = model.classify.constantize.send(request[:m],*request[:a]) 
        
        #else type is an object
        else
          #ensure the object is of proper type:
          if request[:o] && request[:o].class.to_s == model.to_s
            response = {}
            if request[:a]
              response[:r] = request[:o].send(request[:m], *request[:a])
            else
              response[:r] = request[:o].send(request[:m])
            end
            response[:o] = request[:o]
          else
            ActiveSocket.log.debug "packed object does not match expected Class type"
            response[:r] = false
          end
        end
        return Protocol.pack(response) 
      end
    
      # Process_connection is used when ActiveSocket needs to process lower-level
      # ActiveRecord requests.  In these cases all calls to connection (client-side)
      # are passed to server via process_connection.  This is not encouraged as there
      # is typically heavy back&forth and is therefore expensive.
      def process_connection(model, body)
        ActiveSocket.log.debug "in process connection"
        found = Protocol.unpack(body)
        attempted = found[:attempted]
        args = found[:args]
        block = found[:block]
        trying = model.classify.constantize.connection.send attempted, *args
        return Protocol.pack(trying)
      end
    
      # reveal structure is called by the client at model initialization.
      # attributes and custom class/instance methods are returned.
      # This is crucial, as it lets the client know how to respond to method
      # requests.
      def reveal_structure(model)
        ActiveSocket.log.debug "in reveal structure!"
        c = model.classify.constantize

        # gather the custom class and instance methods
        # defined in our model...
        fake = c.const_defined?(:Faker) ? c.const_get(:Faker) : c.const_set("Faker", Class.new(ActiveRecord::Base))
        meths = {}
        meths[:inst] = c.instance_methods - fake.instance_methods
        meths[:class] = c.methods - fake.methods
        
        # Now take out instance methods associated with columns
        # as those methods should be local to the client
        c.columns.each do |s|
          meths[:inst] = meths[:inst] - ["#{s.name}","#{s.name}=" ]
        end
        
        # We don't want to include the actual ConnectionAdapter.  
        # So we loop through and take what we need.
        columns = []
        c.columns.each do |s|
          col = {:name => s.name, :default => s.default, :sql_type => s.sql_type, :null => s.null}
          columns << col
        end
        
        associations = c.reflections
        
        structure = {:cols => columns, :methods => meths, :assoc => associations}
        return Protocol.pack(structure)
      end
  end
end