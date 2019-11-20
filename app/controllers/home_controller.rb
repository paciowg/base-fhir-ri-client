class HomeController < ApplicationController

  before_action :establish_session_handler, only: [ :index ]

  def index
  end

  private

  def establish_session_handler
    SessionHandler.establish(session.id)
  end

end
