# Cross Process Tweeting with BirdGrinder #

BirdGrinder ships with a simple tweeting queue based on redis. In other words,
a simple built in way for users to do asynchronous tweeting (via one account)
by adding items to a redis list.

## Starting the Processor ##

Enabling the queue processor is simple, first you need to:

    gem install Sutto-em-redis
  
And then its simply a matter of adding:

    BirdGrinder::QueueProcessor.start
    
inside the `once_running` block in the your `config/setup.rb`.

Once that's done (and assuming you have redis running correctly), you should then have
a semi-persistent queue for sending direct messages and tweets from other processes.

Please note that it makes no promises about whether messages will be delivered / how
long it will take for messages to be sent.

Also, if you wish to use a custom key (in redis, e.g. "my-app:twitter-messages"), simply
do:

    BirdGrinder::QueueProcessor.namespace = "my-app:twitter-messages"

## Scheduling Messages ##

To schedule a message, you need simply generate json of roughly the following
format and append it to the list at the namespace above:

    {"action": "dm", "arguments": ["user-to-tweet-to", "your-tweet"]}
    
OR

    {"action": "tweet", "arguments": ["your-tweet"]}
    
A reference client which should work for most ruby uses is available in `examples/bird_grinder_client.rb`.
To use it, it's as simple as:

    require 'example/bird_grinder_client'
    # Set namespace if customized.
    BirdGrinderClient.namespace = "my-app:twitter-messages"
    # Create a client
    client = BirdGrinderClient.new
    client.tweet "Hello world via BirdGrinder"
    # OR
    client.dm "Sutto", "Woah! I'm playing with BirdGrinder"
    
If a connection is refused, `BirdGrinderClient::Error` is raised.
    