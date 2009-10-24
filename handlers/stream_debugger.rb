class StreamDebugger < BirdGrinder::Base
  
  on_event :incoming_stream, :process_stream_tweet
  
  @@tweets = {}
  
  def process_stream_tweet
    return unless options.stream_type?
    case options.stream_type
    when :tweet
      @@tweets[options.id] = options
    when :delete
      puts "Delete, got: #{options.inspect}"
    when :limit
      puts "Limited, got: #{options.inspect}"
    end
  end
  
end