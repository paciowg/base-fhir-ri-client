class HomeController < ApplicationController

  before_action :establish_session_tracker, only: [ :index ]

  def index
  end

  private

  def establish_session_tracker
    SessionTracker.establish(session.id)
  end

end
