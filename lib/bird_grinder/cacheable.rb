require 'moneta'
require 'moneta/memory'

module BirdGrinder
  
  class << self
    
    def cache_store
      @@__cache_store__ ||= Moneta::Memory.new
    end
  
    def cache_store=(cs)
      @@__cache_store__ = cs
    end
  
    alias use_cache cache_store=
    
  end
  
  module Cacheable
    
    def self.included(parent)
      parent.send(:include, Methods)
      parent.send(:extend,  Methods)
    end
    
    module Methods
      
      def cache_get(key)
        cs = BirdGrinder.cache_store
        cs && cs[key.to_s]
      end
      
      def cache_set(key, value)
        cs = BirdGrinder.cache_store
        cs && cs[key.to_s] = value
      end
      
    end
    
  end
end