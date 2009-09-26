require 'moneta'
require 'moneta/memory'

module BirdGrinder
  
  class << self
    
    # Gets the current cache store in use. Defaults
    # to Moneta::Memory
    #
    # @see http://github.com/wycats/moneta
    # @see Moneta::Redis
    # @see Moneta::BasicFile
    def cache_store
      @@__cache_store__ ||= Moneta::Memory.new
    end
  
    # Sets the cache store to a hash-like object.
    #
    # @param [Object] cs the cache store (must be hash-like with #[] and #[]=)
    def cache_store=(cs)
      @@__cache_store__ = cs
    end
  
    alias use_cache cache_store=
    
  end
  
  module Cacheable
    
    # Gives the target class cache_set and cache_get
    # on a class and instance level. triggered by:
    #   include BirdGrinder::Cacheable
    def self.included(parent)
      parent.send(:include, Methods)
      parent.send(:extend,  Methods)
    end
    
    module Methods
      
      # Gets the value for the given key from the
      # cache store if the cache store is set.
      #
      # @param [Symbol] key the key to get the value for
      # @return [Object] the value for the given key
      # @see BirdGrinder.cache_store
      def cache_get(key)
        cs = BirdGrinder.cache_store
        cs && cs[key.to_s]
      end
      
      # Attempts to set the value for a given key in the
      # current cache_store.
      #
      # @param [Symbol] key the key to set the value for
      # @param [Object] value the value for said key
      # @see BirdGrinder.cache_store
      def cache_set(key, value)
        cs = BirdGrinder.cache_store
        cs && cs[key.to_s] = value
      end
      
    end
    
  end
end