class SessionTracker

  @sessions = Hash.new

  def self.establish(sessionID)
    if established?(sessionID)
      @sessions[sessionID][:last_used] = Time.now
    else
      @sessions[sessionID] = { last_used: Time.now}#, si: ServerInteraction.new, ss: SessionStorage.new  }
    end
    prune()
  end

  def self.established?(sessionID)
    !@sessions[sessionID].nil?
  end

  def self.prune() 
    safe_hours = 5 
    @sessions.delete_if{ |sessionID, session| (Time.now - session[:last_used]) > (safe_hours * 60 * 60) }
  end

end