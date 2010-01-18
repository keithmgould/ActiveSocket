require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + '/../../server/active_socket.rb'
include ActiveSocket


ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database => "#{File.dirname(__FILE__)}/test.sqlite3",
    :pool => 3,
    :timeout => 5000)

#first delete the database
if File.exists? "#{File.dirname(__FILE__)}/test.sqlite3"
  File.delete "#{File.dirname(__FILE__)}/test.sqlite3" 
end

#then create the database
ActiveRecord::Schema.define do
    create_table :blogs do |t|
      t.integer :author_id, :null => false
      t.string :title, :null => false
    end
    
    create_table :posts do |t|
      t.integer :blog_id, :null => false
      t.string :body, :null => false
    end
end

class Blog < ActiveRecord::Base
  has_many :posts
  def self.custom_class_method
    "hello from a class method"
  end
  
  def custom_instance_method
    "hello from an instance method"
  end
end

class Post < ActiveRecord::Base
  belongs_to :blog
end

ActiveSocketServer.new(4010)