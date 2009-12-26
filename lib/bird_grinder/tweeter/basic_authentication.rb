module BirdGrinder
  class Tweeter
    class BasicAuthentication
      
      def initialize
        @basic_auth_credentials = [BirdGrinder::Settings.username, BirdGrinder::Settings.password]
        generate_header!
      end
      
      attr_reader :basic_auth_credentials
      
      # Authenticats a given request using Basic Authentication.
      def header_for(request, http_method, opts = {})
        @auth_header
      end
      
      protected
      
      def generate_header!
        @auth_header = ["Basic #{@basic_auth_credentials.join(":")}"].pack('m*')
      end
      
    end
  end
end