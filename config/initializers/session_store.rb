# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_c-unit_session',
  :secret      => 'b469a5e0fc74955adb1e67eb2e96d83a0597068e3678982dcd58b21a968bf8567bd6453d3cc28e60090242df72b1632076d22691d72968fdd504506625bd0587'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
