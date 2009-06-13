module ActiveSocket
  module Processors
    
      private 
      
      def process_message(message)
        begin
          command, model, body = message.chomp.split(":")
          Global.log.debug "processing: #{command} on #{model}"
          case command
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
            else
              raise
          end
        rescue
         # Note: we should never need to get rescued.
         # If we do, fortify offending method below.
         Global.log.warn "failed in process_message: #{$!}"
         response = Protocol.pack("failure: unable to process message: #{$!}")
        end
        return (response + "\n")
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
        Global.log.debug "in process update"
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
        Global.log.debug "in process destroy"
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
        Global.log.debug "in process delete"
        conditions = Protocol.unpack(body) if body
      
        response = model.classify.constantize.delete_all(conditions)
        return Protocol.pack(response)
      end
      
      def passalong_object(model,body)
        Global.log.debug "in passalong"
        request = Protocol.unpack(body)
        if request[:t] == "c"
          response = model.classify.constantize.send(request[:m],*request[:a]) 
        else
          #ensure the object is of proper type:
          if request[:o] && request[:o].class.to_s == model.to_s
            response = {}
            response[:r] = request[:o].send(request[:m], *request[:a])
            response[:o] = request[:o]
          else
            Global.log.debug "packed object does not match expected Class type"
            response[:r] = false
          end
        end
        return Protocol.pack(response) 
      end
    
      def process_connection(model, body)
        Global.log.debug "in process connection"
        found = Protocol.unpack(body)
        attempted = found[:attempted]
        args = found[:args]
        block = found[:block]
        trying = model.classify.constantize.connection.send attempted, *args
        return Protocol.pack(trying)
      end
    
      def reveal_structure(model)
        Global.log.debug "in reveal structure!"
        c = model.classify.constantize

        # gather the custom class and instance methods
        # defined in our model...
        fake = c.const_defined?(:Faker) ? c.const_get(:Faker) : c.const_set("Faker", Class.new(ActiveRecord::Base))
        meths = {}
        meths[:inst] = c.instance_methods - fake.instance_methods
        meths[:class] = c.methods - fake.methods
      
      
        # We don't want to include the actual ConnectionAdapter.  
        # So we loop through and take what we need.
        columns = []
        c.columns.each do |s|
          c = {:name => s.name, :default => s.default, :sql_type => s.sql_type, :null => s.null}
          columns << c
        end
        structure = {:cols => columns, :methods => meths}
        return Protocol.pack(structure)
      end
  end
end