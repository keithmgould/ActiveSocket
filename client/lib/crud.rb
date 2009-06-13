# Note: I left the variable names as single letters to keep the size of transmission as small as possible

module ActiveSocket
  module ClassCrud
    
    def find(*args)
      request = {:m => "find", :a => args}
      communicate("read",self.to_s,request)
    end
    
    def delete_all(conditions = nil)
      communicate("delete",self.to_s,conditions)
    end
    
  end
  
  module InstanceCrud
    
    # I override save and save! due to callbacks 
    # (before_save transaction stuff).  I'd rather 
    # just turn that off than redefining these here...
    # how?
    def save
      create_or_update
    end
    
    def save!
      create_or_update || raise(RecordNotSaved)
    end
    
    def create
      response = self.class.communicate("create",self.class.to_s, self)
      success = response[:success]
      obj = response[:obj]
      if success
        # can not do self.attributes = obj.attributes
        # due to potential mass assignment issues
        obj.attributes.each_pair do |k,v|
          self.send("#{k}=", v)
        end
        
        self.send("changed_attributes").send("clear")
        @new_record = false
        response = true
      else
        response = false
      end
      return response
    end
    
    def update
      return true unless changed?
      a = {}
      changed.each do |cattr|
        a[cattr] = self.send(cattr)
      end
      request = {:id => id, :a => attributes}
      response = self.class.communicate("update",self.class.to_s,request)
      if response
        self.send("changed_attributes").send("clear")
      end
      return response
    end
    
    def destroy
      response = self.class.communicate("destroy",self.class.to_s,id)
      freeze if response
    end
    
  end
end