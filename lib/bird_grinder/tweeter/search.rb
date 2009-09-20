module BirdGrinder
  class Tweeter
    class Search
      
      cattr_accessor :search_base_url
      self.search_base_url = "http://search.twitter.com/"
      
      def initialize
        logger.debug "Initializing Search"
      end
      
      def search_for(query, opts = {})
        url = search_base_url / "search.json"
        request = EventMachine::HttpRequest.new
      end
      
    end
  end
end