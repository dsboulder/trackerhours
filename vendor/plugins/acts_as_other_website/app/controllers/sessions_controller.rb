class SessionsController < ApplicationController
  LoginSession = Struct.new(:username, :password)
  skip_before_filter :create_mechanized_session
  skip_after_filter :store_mechanized_session, :only => :new

  def new
    @session = LoginSession.new(params[:username], nil)
  end

  def create
    @mechanized_session = acts_as_other_website_options[:using].new(params[:session].merge(:logger =>logger))
    flash[:notice] = "Login successful"
    redirect_to root_path
  end
end