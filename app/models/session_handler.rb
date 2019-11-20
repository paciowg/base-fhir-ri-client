class SessionHandler

  @sessions = Hash.new

  def self.establish(sessionID, url = nil, oauth2_id = nil, oauth2_secret = nil)
    if established?(sessionID)
      @sessions[sessionID][:active] = Time.now
    else
      @sessions[sessionID] = { active: Time.now }
      @sessions[sessionID][:fsi] = FhirServerInteraction.new(url, oauth2_id, oauth2_secret)
      @sessions[sessionID][:ss] = Hash.new
    end
    prune
  end

  def self.reset_connection(sessionID, url = nil, oauth2_id = nil, oauth2_secret = nil)
    establish(sessionID)
    @sessions[sessionID][:fsi].connect(url, oauth2_id, oauth2_secret)
  end

  def self.fhir_client(sessionID)
    establish(sessionID)
    @sessions[sessionID][:fsi].client
  end

  def self.all_resources(sessionID, klasses, search = {})
    establish(sessionID)
    @sessions[sessionID][:fsi].all_resources(klass, search)
  end

  def self.store(sessionID, key, value)
    establish(sessionID)
    @sessions[sessionID][:ss][key] = value
  end

  def self.from_storage(sessionID, key)
    establish(sessionID)
    @sessions[sessionID][:ss][key]
  end

  def self.storage(sessionID)
    establish(sessionID)
    @sessions[sessionID][:ss]
  end

  private

  # Number of hours a session can go stale before becoming liable to get wiped
  @safe_hours = 2

  def self.prune
    @sessions.delete_if{ |id, session| (Time.now - session[:active]) > (@safe_hours * 3600) }
  end

  def self.established?(sessionID)
    !@sessions[sessionID].nil?
  end

end