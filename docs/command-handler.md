## Super simple bots via BirdGrinder::CommandHandler ##

One of the most common uses for birdgrinder is to write
simple command-based bots. E.g. bots that response to:

    @yourbot help
    
or
    
    @yourbot whois @sutto

etc. To do this, you can simply subclass `BirdGrinder::CommandHandler`,
define a method (e.g. "help", "whois") that accepts a single argument (everything
in the tweet AFTER the command) and then call exposes.

E.g., create `handlers/my_awesome_bot.rb`, And add the following code:

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
    
Also note, you can set MyAwesomeBot.command\_prefix to change the way the text is triggered.

    MyAwesomeBot.command_prefix = "!"
    
would only work if the user tweeted:

    @yourbot !help
    @yourbot !whois @sutto

Or sent a direct message to yourbot like:

    !help
    !whois @sutto

