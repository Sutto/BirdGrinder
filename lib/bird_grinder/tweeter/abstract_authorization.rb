module BirdGrinder
  class Tweeter
    class AbstractAuthorization
      
      is :loggable
      
      def add_header_to(http)
        headers = (http.options[:head] ||= {})
        headers['Authorization'] = self.header_for(http)
      end
      
      def header_for(http)
        raise NotImplementedError
      end
      
    end
  end
end
  