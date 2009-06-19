#Test the entire ActiveSocket Suite...

require 'test/unit'

# Both client and server share the protocol class for communication.
require 'common/protocol_test'

# Test client commnicating with server via connection class.
require 'client/connection_test'