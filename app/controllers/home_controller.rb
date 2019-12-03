class HomeController < ApplicationController

  before_action :establish_session_handler, only: [ :index ]

  def index
  end

  private

  def establish_session_handler
    Thread.new do
      while (session.id.nil?) # rails session info loads lazily
        sleep(0.1)
      end
      SessionHandler.establish(session.id)
    end
  end

end
