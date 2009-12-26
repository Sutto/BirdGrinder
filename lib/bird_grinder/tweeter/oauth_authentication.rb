require 'oauth'

module BirdGrinder
  class Tweeter
    class OauthAuthentication
      
      # Authenticats a given request.
      def header_for(request, http_method, opts = {})
        uri = uri_for_request(request, http_method)
        
      end
      
      protected
      
      def uri_for_request(r, p)
        r.instance_variable_get(:@uri).dup
      end
      
      def oauth_consumer
        @oauth_consumer ||= begin
          settings = BirdGrinder::Settings.oauth
          site = Tweeter.api_base_url.gsub(/\/$/, '')
          OAuth::Consumer.new(settings.consumer_key, settings.consumer_secret, :site => site)
        end
      end
      
    end
  end
end