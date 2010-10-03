require_dependency "tracker_session"

class ApplicationController < ActionController::Base
  protect_from_forgery
  
  acts_as_other_website :using => TrackerSession
end
