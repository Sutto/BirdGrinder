module BirdGrinder
  class Tweeter
    class StreamProcessor
      is :loggable
      
      def initialize(parent, stream_name)
        @parent = parent
        @stream_name = stream_name.to_sym
        setup_parser
      end
      
      def receive_chunk(chunk)
        @parser << chunk
      rescue Yajl::ParseError => e
        logger.error "Couldn't parse json: #{e.message}"
      end
      
      def process_stream_item(json)
        return if !json.is_a?(Hash)
        processed = json.to_nash.normalized
        processed.type = lookup_type_for_steam_response(processed)
        processed.streaming_source = @stream_name
        logger.info "Processing Stream Tweet #{processed.id}: #{processed.text}"
        @parent.delegate.receive_message(:incoming_stream, processed)
      end
   
      protected
      
      def lookup_type_for_steam_response(response)
        if response.delete?
          :delete
        elsif response.limit?
          :limit
        else
          :tweet
        end
      end
      
      def setup_parser
        @parser = Yajl::Parser.new
        @parser.on_parse_complete = method(:process_stream_item)
      end
      
    end
  end
end