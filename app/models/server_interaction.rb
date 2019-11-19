class ServerInteraction
  
  # Automatically set to HAPI's public testing FHIR server
  # TODO - REMEMBER TO REPLACE WITH YOUR FHIR SERVER'S BASE URL
  @base_server_url = "http://hapi.fhir.org/baseR4"

  def initialize
    set_connection
  end

  def set_connection(url = nil)
    url = url.nil? ? @base_server_url : url
    @client = FHIR::Client.new(url)
    FHIR::Model.client = @client
  end
  
  def get_resources(klasses = nil, search = nil)
    replies = get_replies(klasses, search)
    return nil unless replies
    resources = []
    replies.each do |reply|
      resources.push(reply.resource.entry.collect{ |singleEntry| singleEntry.resource })
    end
    resources.compact!
    resources.flatten(1)
  end

  def get_client
    @client
  end

  private
  
  def get_replies(klasses = nil, search = nil)
    klasses = coerce_to_a(klasses)
    replies = []
    if klasses.present?
      klasses.each do |klass|
        replies.push(search.present? ? @client.search(klass, search) : @client.read_feed(klass))
        while replies.last
          replies.push(@client.next_page(replies.last))
        end
      end
    else
      replies.push(@client.all_history)
    end
    replies.compact!
    replies.blank? ? nil : replies
  end

  def coerce_to_a(object)
    return nil unless object
    object.respond_to?('to_a') ? object.to_a : Array.[](object)
  end

end