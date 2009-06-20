# Run the entire ActiveSocket Test Suite...

# Bring the love.
require 'test/unit'

# Both client and server communicate with the Protocol class
require 'common/protocol_test'

# Test client's Connection class.
require 'client/connection_test'

# Test client's CRUD actions
require 'client/crud_test'