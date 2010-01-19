require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + '/../../server/active_socket.rb'
include ActiveSocket

# first delete the database
if File.exists? "#{File.dirname(__FILE__)}/test.sqlite3"
  File.delete "#{File.dirname(__FILE__)}/test.sqlite3" 
end

# This will create the db file if it does not exist.
ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database => "#{File.dirname(__FILE__)}/test.sqlite3")

puts "................established connection (#{Time.new})"

#then create the database
ActiveRecord::Schema.define do
    create_table :blogs do |t|
      t.integer :author_id, :null => false
      t.string :title, :null => false
      t.string :publisher, :null => true
      t.date   :published_on, :null => true
    end
    
    create_table :posts do |t|
      t.integer :blog_id, :null => false
      t.string :body, :null => false
    end
end
puts "................defined schema (#{Time.new})"

class Blog < ActiveRecord::Base
  has_many :posts
  named_scope :with_publisher, :conditions => ["publisher is not null"]
  named_scope :published_this_week, :conditions => ["published_on > ?", 1.week.ago.to_date ]
  
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

puts "................classes defined (#{Time.new})"
puts "................about to start server... (#{Time.new})"

ActiveSocketServer.new(4010, :development)