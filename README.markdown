BirdGrinder - an evented ruby twitter library
---------------------------------------------

BirdGrinder is my attempt at an evented twitter library / "framework"
for ruby. Based on Perennial and very much influenced by [Marvin](http://github.com/Sutto/marvin)'s design, even to the
level of sharing a lot of code, BirdGrinder is designed to make
it simple and easy to create twitter bots / clients that react to
events such as processing searches / streams, automatically processing
mentions and direct messages.

One example of this usage is for a twitter game - BirdGrinder was
originally written for use in Nick Plante's upcoming werewolf game.

Getting Started
===============

First up, make sure you have [gemcutter](http://gemcutter.org/) and
[GitHub's rubygem repo](http://gems.github.com/) added to your gem
sources. Once that's done, it should be as simple as doing:

    gem install birdgrinder
  
Which adds a birdgrinder executable. Like marvin, BirdGrinder works
both when used directly with the source (e.g. you fork BirdGrinder, 
add handlers etc there) and in an instance form. To create an instance,
you simply do:

    birdgrinder create path-to-my-new-instances-folder
  
Which will generate a folder and some files. If you change into that
directory, you only really need to care about three parts:

- config/settings.yml - this specifies your authentication etc infromation
- config/setup.rb - lets you register handlers and the like
- handlers/* - where your handlers are stored.

If you put details of a twitter account in the settings file, you can then
start the default client which will process the debug handler. E.g.:

    birdgrinder client --verbose
  
or, if you're not in the apps directory,

    birdgrinder client path-to-my-app --verbose
  
Also, BirdGrinder console will let you start up an irb instance with
settings etc loaded. So,

    birdgrinder console
  
in your apps directory, otherwise:

    birdgrinder console path-to-my-app
  
Creating new handlers is a simple case of creating handlers/your\_handler\_name.rb
(or whatever it is called), subclassing BirdGrinder::Base or BirdGrinder::CommandHandler
and then registering it (like DebugHandler) in config/setup.rb

BirdGrinder::CommandHandler
===========================

One of the most common uses for BirdGrinder is to write
simple command-based bots. E.g. bots that response to:

    @yourbot help
    
or
    
    @yourbot whois @sutto

etc. To do this, you can simply subclass BirdGrinder::CommandHandler,
define a method (e.g. "help", "whois") that accepts a single argument (everything
in the tweet AFTER the command) and then call exposes. E.g.

    class MyAwesomeBot < BirdGrinder::CommandHandler
      
      exposes :help, :whois
      
      def help(text)
        reply "RTFM, kk?"
      end
      
      def whois(name)
        if name.blank?
          reply "I need a name!"
        else
          reply "I have no idea who #{name} is!"
        end
      end
      
    end
    
Also note, you can set MyAwesomeBot.command\_prefix to change the way it is matched.
e.g:

    MyAwesomeBot.command_prefix = "!"
    
would only work if the user did:

    @yourbot !help
    @yourbot !whois @sutto

Contributing
============

I welcome any and all contributions, but please keep a few things in mind:

- I have the right to decide what gets pulled in.
- If you maintain your own version, please bump it in separate commits to actual functionality.

Any Questions?
==============

Contact sutto@sutto.net or ping SuttoL on Freenode