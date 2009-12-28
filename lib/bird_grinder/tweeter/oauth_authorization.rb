require 'oauth'
require 'em-http-oauth-request'

module BirdGrinder
  class Tweeter
    class OAuthAuthorization< AbstractAuthorization
      
      # Authenticates a given request.
      def header_for(request)
        OAuth::Client::Helper.new(request, {
          :token    => self.class.oauth_access_token,
          :consumer => self.class.oauth_consumer
        }).header
      end
      
      def self.enabled?
        oauth = BirdGrinder::Settings.oauth
        oauth.present? && [:consumer_key, :consumer_secret, :access_token_token, :access_token_secret].all? { |k| oauth[k].present? }
      end
      
      # From the twitter gem, with modification
      def self.retrieve_access_token!(raw_request_token, request_secret, pin)
        request_token = OAuth::RequestToken.new(self.oauth_consumer, raw_request_token, request_secret)
        access_token  = request_token.get_access_token(:oauth_verifier => pin)
        original_settings = BirdGrinder::Settings.oauth.to_hash
        original_settings.merge! :access_token_token => access_token.token,
                                 :access_token_secret => access_token.secret
        BirdGrinder::Settings.update! :oauth => original_settings.stringify_keys
      end
      
      def self.request_token
        @request_token ||= self.oauth_consumer.get_request_token
      end
      
      protected
      
      def self.oauth_consumer
        @oauth_consumer ||= begin
          settings = BirdGrinder::Settings.oauth
          site = Tweeter.api_base_url.gsub(/\/$/, '')
          OAuth::Consumer.new(settings.consumer_key, settings.consumer_secret, :site => site)
        end
      end
      
      def self.oauth_access_token
        @oauth_access_token ||= begin
          settings = BirdGrinder::Settings.oauth
          OAuth::AccessToken.new(self.oauth_consumer, settings.access_token_token, settings.access_token_secret)
        end
      end
      
    end
  end
end