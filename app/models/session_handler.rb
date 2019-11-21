##
# +SessionHandler+ provides basic server-side session-specific utilities for reference 
# implementation FHIR clients
# 
# All methods require a +session_id+ parameter to know which session they are dealing with, 
# generally speaking this should come from a +session.id+ call from a +Controller+
#
# <b>Do not initialize this class, reference it statically</b>

class SessionHandler

  @sessions = Hash.new


  ##
  # Establishes connection to a FHIR server by instantiating +FhirServerInteraction+
  # 
  # Creates new +Hash+ to allow for server-side, session-specific data storage and access in 
  # memory 
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # Calls private +prune+ method to weed out old sessions
  #
  # *Params*
  #
  # * +session_id+ - indicates which session to establish a +SessionHandler+ for (use 
  #   +session.id+)
  #
  # * +url+ - _Optional_ _param_, overrides <code>@base_server_url</code> from 
  #   +FhirServerInteraction+ and replaces it as the default connection url for this session
  #
  # * +oauth2_id+ - _Optional_ _param_, overrides <code>@oauth2_id</code> from 
  #   +FhirServerInteraction+ and replaces it as the default OAuth2 ID for this session
  #
  # * +oauth2_secret+ - _Optional_ _param_, overrides <code>@oauth2_secret</code> from 
  #   +FhirServerInteraction+ and replaces it as the default OAuth2 secret for this session

  def self.establish(session_id, url = nil, oauth2_id = nil, oauth2_secret = nil)
    if established?(session_id)
      @sessions[session_id][:active] = Time.now
      prune
    else
      prune
      @sessions[session_id] = { active: Time.now }
      @sessions[session_id][:fsi] = FhirServerInteraction.new(url, oauth2_id, oauth2_secret)
      @sessions[session_id][:ss] = Hash.new
    end
  end


  ##
  # Resets +FhirServerInteraction+ connection according to the provided params
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # *Params*
  #
  # * +session_id+ - indicates which session to reset the connection (use +session.id+)
  #
  # * +url+ - _Optional_ _param_, overrides <code>@base_server_url</code> from 
  #   +FhirServerInteraction+ and replaces it as the default connection url for this session
  #
  # * +oauth2_id+ - _Optional_ _param_, overrides <code>@oauth2_id</code> from 
  #   +FhirServerInteraction+ and replaces it as the default OAuth2 ID for this session
  #
  # * +oauth2_secret+ - _Optional_ _param_, overrides <code>@oauth2_secret</code> from 
  #   +FhirServerInteraction+ and replaces it as the default OAuth2 secret for this session

  def self.reset_connection(session_id, url = nil, oauth2_id = nil, oauth2_secret = nil)
    active(session_id)
    @sessions[session_id][:fsi].connect(url, oauth2_id, oauth2_secret)
  end


  ##
  # Gets +FHIR::Client+ instance associated with the provided +session_id+
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # *Params*
  #
  # * +session_id+ - Indicates which session to get the +FHIR::Client+ from (use +session.id+)

  def self.fhir_client(session_id)
    active(session_id)
    @sessions[session_id][:fsi].client
  end


  ##
  # Makes search requests of the connected FHIR server for each klass represented in klasses, 
  # and iterates through the resulting bundles to provide an array of every returned resource
  # 
  # Basically a helper method to provide more functionality on top of what the +FHIR::Client+ can 
  # already do
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # *Params*
  # 
  # * +session_id+ - Indicates which session's +FHIR::Client+ to use for executing searches (use 
  #   +session.id+)
  # 
  # * +klasses+ - An array of +FHIR::Klass+ types to search for (e.g. <code>[FHIR::Patient, 
  #   FHIR::Practitioner]</code> or <code>[FHIR::Questionnaire]</code>)
  # 
  # * +search+ - _Optional_ _param_, provides search specifications for your resource query. If 
  #   unspecified, returns all resources from server matching +klasses+. If specified, follows 
  #   same format as other +FHIR::Client+ search hashes (e.g. <code>search = { search: { 
  #   parameters: { _count: 50 } } }</code> )
  #
  # *Returns* - An array full of every instance the associated server holds of +klasses+ that, if 
  # specified, match the +search+

  def self.all_resources(session_id, klasses, search = {})
    active(session_id)
    @sessions[session_id][:fsi].all_resources(klass, search)
  end


  ##
  # Stores +value+ in this sessions in-memory storage to be later retrieved by +key+
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # *Params*
  # 
  # * +session_id+ - Indicates which session's storage to store +value+ in (use +session.id+)
  # 
  # * +key+ - The key to associate +value+ with for future retrieval
  # 
  # * +value+ - The value to store for future access

  def self.store(session_id, key, value)
    active(session_id)
    @sessions[session_id][:ss][key] = value
  end


  ##
  # Retrieves a value from storage by its +key+
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # *Params*
  #
  # * +session_id+ - Indicates which session's storage to access (use +session.id+)
  # 
  # *Returns* - A specific value from storage that was stored with the provided +key+

  def self.from_storage(session_id, key)
    active(session_id)
    @sessions[session_id][:ss][key]
  end


  ##
  # Gets the specified session's entire storage hash
  # 
  # Updates active timer for this session to prevent premature pruning
  # 
  # *Params*
  # 
  # * +session_id+ - Indicates which session's storage hash to retrieve (use +session.id+)
  # 
  # *Returns* - A hash of every key-value pairing this session has stored

  def self.storage(session_id)
    active(session_id)
    @sessions[session_id][:ss]
  end


  ##
  # Updates last active time for session to prevent premature pruning
  # 
  # *Params*
  #
  # * +session_id+ - indicates which session to refresh active status for (use +session.id+)

  def self.active(session_id)
    if established?(session_id)
      @sessions[session_id][:active] = Time.now
    else
      establish(session_id)
    end
  end

  private

  # Number of hours a session can go stale before becoming liable to get wiped
  @safe_hours = 2

  def self.prune
    @sessions.delete_if{ |id, session| (Time.now - session[:active]) > (@safe_hours * 3600) }
  end

  def self.established?(session_id)
    !@sessions[session_id].nil?
  end

end