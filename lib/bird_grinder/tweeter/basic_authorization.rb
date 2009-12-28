module BirdGrinder
  class Tweeter
    class BasicAuthorization < AbstractAuthorization
      
      def initialize
        @basic_auth_credentials = [BirdGrinder::Settings.username, BirdGrinder::Settings.password]
      end
      
      attr_reader :basic_auth_credentials
      
      # Authenticats a given request using Basic authorization.
      def header_for(http)
        @basic_auth_credentials
      end
      
      protected
      
      def generate_header!
      end
      
    end
  end
end