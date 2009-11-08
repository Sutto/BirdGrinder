# Super simple bots via BirdGrinder::StreamHandler #

`BirdGrinder::StreamHandler` is a subclass of `BirdGrinder::Base` tailored to
making working with Twitter's new streaming API simple. In essence, it works
exactly the sample as a `BirdGrinder::Base`-based handler but it provides
a set of class methods to make it easy.

## Starting Streaming Methods ##

- `sample(opts = {})` - uses the streaming api's sample feed; A random assortment of tweets.
- `filter(opts = {})` - uses the streaming api's filter feed, specify follow and track via opts.
- `follow(*args)` - uses the streaming api's filter feed with a set of user id's. e.g: follow 1, 2, 3, 4, :my => 'opts'
- `track(*args)` - uses the streaming api's filter feed w/ a specific track term + options.

e.g.:

    class MySampleStreamHandler < BirdGrinder::StreamHandler
      
      # Get a sampe feed
      sample
      
      # Filter directly...
      filter :track => "twitter,facebook", :follow => "1,2,3,4,5"
      
      # Follow a set of users
      follow 1, 2, 3, 4, 5
      # OR
      follow [1, 2, 3, 4, 5]
      
      # Finally, short hand for track.
      track "hello", "there"
      # OR
      track ["hello", "there"]
      
    end

## Processing Stream Items ##

Since the stream has three types of items (tweets, rate limit notices and deletes)
shortcuts similar to `on_event` are made available (with the exception they only
take blocks, not symbols referring to methods):

- `tweet_from_stream(name, &blk)` - calls blk on a stream name (e.g. :sample, :filter, :track, :follow) given a tweet. Standard tweet data is available in options.
- `delete_from_stream(name, &blk)` - calls blk on a stream name (e.g. :sample, :filter, :track, :follow) given a delete. Options is the contents of the status part of the response (id is the twitter id, user\_id is the tweeter id)
- `rate_limit_from_stream(name, &blk)` - calls blk on a stream name (e.g. :sample, :filter, :track, :follow) given a rate limit notice. Options has a single 'track' item, the number of missed tweets.

e.g.:

    class MySampleStreamHandler < BirdGrinder::StreamHandler
      
      track "followfriday"
      
      @@tweets = {}
      
      tweet_from_stream :track do
        @@tweets[options.id] = options.dup
        puts "#{options.user.screen_name} said: #{options.text}"
      end
      
      delete_from_stream :track do
        puts  "Tweet ##{options.id} was deleted"
        @@tweets.delete(options.id)
      end
      
      rate_limit_from_stream :track do
        puts "Missed #{options.track} tweets"
      end
      
    end
