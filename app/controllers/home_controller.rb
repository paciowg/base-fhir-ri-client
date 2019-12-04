class HomeController < ApplicationController

  before_action :establish_session_handler, only: [ :index ]

  def index
  end

  private

  def establish_session_handler
    session[:wake] = "up" # prompts rails session to load
    SessionHandler.establish(session.id)
  end

end
