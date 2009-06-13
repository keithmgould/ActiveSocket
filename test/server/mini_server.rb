require 'rubygems'
require 'activerecord'
require File.dirname(__FILE__) + '/../../server/active_socket.rb'
include ActiveSocket

module Global 
  def log
    @log ||= Logger.new("debug.log")
  end
end
include Global
Global.log.level = Logger::DEBUG
  
ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database => "test.sqlite3",
    :pool => 3,
    :timeout => 5000)

#first delete the database
File.delete "test.sqlite3" if File.exists? "test.sqlite3"

#then create the database
ActiveRecord::Schema.define do
    create_table :blogs do |t|
      t.integer :author_id, :null => false
      t.string :title, :null => false
    end
  end

class Blog < ActiveRecord::Base

end