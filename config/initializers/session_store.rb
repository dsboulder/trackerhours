# Be sure to restart your server when you modify this file.

Trackerhours2::Application.config.session_store :cookie_store,
                                                :key => '_trackerhours2_session',
                                                :expires => 20.years.from_now.utc

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Trackerhours2::Application.config.session_store :active_record_store
