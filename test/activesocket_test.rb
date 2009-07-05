# Run the entire ActiveSocket Test Suite...

# Bring the love.
require 'test/unit'

# Both client and server communicate with the Protocol class
require File.dirname(__FILE__) + '/common/protocol_test'

# Test client's Connection class.
require File.dirname(__FILE__) + '/client/connection_test'

# Test client's knowledge of model
require File.dirname(__FILE__) + '/client/structure_test'

# Test client's CRUD actions
require File.dirname(__FILE__) + '/client/crud_test'