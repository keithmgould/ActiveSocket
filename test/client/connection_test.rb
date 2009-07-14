require 'rubygems'
require 'shoulda'
require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class ConnectionTest < Test::Unit::TestCase
  
  context "A connection" do
    setup do
      #set up the server
      @server = Thread.new do
        system "ruby #{File.dirname(__FILE__)}/../server/mini_server.rb"
      end

      # wait for server to start up
      sleep 1
    end
    
    context "pointing to a working server" do
       setup do
         
         # proper server parameters
         @c = Connection.new("Object", "localhost", 4010)
         
         #test object passed to server
         obj = Object.new
         @request = {:t => 'i', :o => obj, :m => "kind_of?", :a => Object}
       end
       
       teardown do
         @c.communicate("exit", "blog")
       end
               
       should "propery communicate with the server" do
         r = @c.communicate("passalong", "Object", @request)
         assert r[:r] == true
       end
    end

    context "with wrong connection parameters" do
      setup do
        @c = Connection.new("Object","localhost", 4011)
        obj = Object.new
        @request = {:t => 'i', :o => obj, :m => "kind_of?", :a => Object}
      end
      
      teardown do
        c = Connection.new("Blog","localhost",4010)
        c.communicate("exit", "blog")
      end
      
      should "raise a ConnectionError" do
        assert_raise ConnectionError do
          r = @c.communicate("passalong", "Object", @request)
        end
      end
    end
  end
end