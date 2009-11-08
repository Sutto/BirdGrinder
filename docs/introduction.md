## Getting Started ##

First up, make sure you have [gemcutter](http://gemcutter.org/)
in your sources. Once that's done, it should be as simple as doing:

    gem install birdgrinder
  
Which adds a birdgrinder executable. Like marvin, birdgrinder works
both when used directly with the source (e.g. you fork birdgrinder, 
add handlers etc there) and in an instance form. To create an instance,
you simply need to run:

    birdgrinder create path-to-my-new-instances-folder
  
Which will generate a folder and some files. If you change into that
directory, you only really need to care about three parts:

- config/settings.yml - this specifies your authentication etc information
- config/setup.rb - where you register handlers, setup other code-side configuration
- handlers/* - where your handlers are stored.

If you put details of a twitter account in the settings file, you can then
start the default client which will process the debug handler. E.g.:

    birdgrinder client --verbose
  
or, if you're not in the apps directory,

    birdgrinder client path-to-my-app --verbose
  
Also, BirdGrinder console will let you start up an irb instance with
settings etc loaded. So, calling:

    birdgrinder console
  
in your apps directory, otherwise:

    birdgrinder console path-to-my-app
  
Creating new handlers is a simple case of creating `handlers/your\_handler\_name.rb`
(or whatever it is called), subclassing `BirdGrinder::Base` or `BirdGrinder::CommandHandler`
and then registering it (like `DebugHandler`) in `config/setup.rb`

## Getting started with BirdGrinder::Base ##

Although there are several built in base handlers (e.g. `BirdGrinder::CommandHandler`
and `BirdGrinder::StreamHandler`) that let us handle common functionality, your handlers
will typically be built on (and you should know about - esp. since the aformentioned 
handlers are subclasses of) `BirdGrinder::Base`.

`BirdGrinder::Base` implements a bunch of handy tasks that make it easier to work
within the bounds of `Perennial::Dispatchable` (around which the event driven interface
is built) esp. given a twitter specific context.

In other words, it's a nicer implementation you'll as a base (instead of a raw class).

To get started, it's important to understand how birdgrinder is event driven. When you
start a bot, using `birdgrinder client`, the following happens:

1. BirdGrinder itself is loaded
2. Unix signals are setup and `before_setup` hooks in BirdGrinder are loaded.
3. The application is daemonized (if specified) then logs are setup and settings loaded.
4. Your code in `config/setup.rb` and code in `handlers/` is loaded.
5. `before_run` hooks are invoked.
6. The eventmachine reactor / event loop is started. Once this happens,
   1. Periodic updates (defined by `check_every`, as seconds in the settings file) are started - this checks mentions and direct message.
   2. `once_running` hooks are invoked (e.g. see the `config/setup.rb`)
7. The application runs until stopped, in which case it performs cleanup.

If you start any other processes (e.g. in the `once_running` hook in `config/setup.rb`,
you use `BirdGrinder::Client.current` to start streaming or searches), they will then
dispatch events as they happen.

To actually do something with tweets / searches etc, you need to create handlers - e.g.
subclasses from `BirdGrinder::Base` or `BirdGrinder::CommandHandler` (etc) and place them
in `handlers/`, then register your class by adding `YourHandlerKlass.register!` inside the
`before_run` block in `config/setup.rb`

Event names are follow a pattern of `:DIRECTION_TYPE`, e.g. `:incoming_stream`, `:outgoing_direct_message`
or event `:incoming_mention` (see `docs/events.md` for more.)

To get started, create `handlers/my_demo_handler.rb` in your generated birdgrinder project
and add the following:

    class MyDemoHandler < BirdGrinder::Base
    end
    
Then, to make it run, inside the `before_run` block in `config/setup.rb`, add `MyDemoHandler.register!`

e.g:

    BirdGrinder::Loader.before_run do
      MyDemoHandler.register!
    end

    BirdGrinder::Loader.once_running do
    end
    
If you start the client, e.g. using `birdgrinder client path-to-project -v -l debug`,
it should now process events and dispatch them to your `MyDemoHandler` class.

Handling a specific event inside your handler class is relatively simple. You need to
edit your handler class and inside the class body, call `on_event` with an event name
argument and either a block or a second symbol with a method name, e.g:

    class MyDemoHandler < BirdGrinder::Base
      
      on_event :incoming_mention do
        logger.info "Contents of tweet: #{options.inspect}"
      end
    
    end
    
is functionally equivalent to:

    class MyDemoHandler < BirdGrinder::Base
  
      on_event :incoming_mention, :print_mentions
      
      def print_mentions
        logger.info "Contents of tweet: #{options.inspect}"
      end

    end
    
Lastly, it's worth noting that inside events you have access to a couple of
methods:

- `options` - the data associated with the current event (e.g. options.text)
- `client` - access to the current client instance
- `user` - the current user name (if present)

Along with a methods for responding:

- `tweet(message, opts = {})` - tweet some text
- `dm(user, message, opts = {})` - send a direct message to a user
- `reply(message, opts = {})` - Send a message in reply to a user, using dm's if they dm'ed you or @-replies if they @-replied you.

e.g. for a bot that replied to all mentions mentions that contain "follow me plz", you'd use:

    class MyDemoHandler < BirdGrinder::Base
    
      on_event :incoming_mention do
        if options.text =~ /follow me plz/i
          reply "Nah, I'm sorry"
        end
      end
    
    end
    
Or, if you wanted to actually follow them, you could use client:

    class MyDemoHandler < BirdGrinder::Base
  
      on_event :incoming_mention do
        if options.text =~ /follow me plz/i
          # Client is our control wrapper, tweeter interacts with twitter.
          client.tweeter.follow user
          reply "Doing it now!"
        end
      end
  
    end
    
