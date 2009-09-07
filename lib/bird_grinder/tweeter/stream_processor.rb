module BirdGrinder
  class Tweeter
    class StreamProcessor
      include BirdGrinder::Loggable
      
      def initialize(parent, stream_name)
        @buffer = BufferedTokenizer.new
        @parent = parent
        @stream_name = stream_name.to_sym
      end
      
      def receive_chunk(chunk)
        @buffer.extract(chunk).each { |l| process_steam_line(l.strip) }
      end
      
      def process_steam_line(line)
        json = JSON.parse(line)
        processed = @parent.send(:status_to_args, json, :tweet)
        processed[:streaming_source] = @stream_name
        logger.warn "Processing Stream Tweet - #{processed[:id]} - #{processed[:text]}"
        @parent.delegate.receive_message(:incoming_stream, processed)
      end
      
    end
  end
end