require 'securerandom'

module OrderTree
  
  # Mixin module that provides a proxy convience functions
  module ProxyOperator
    #@param [Object] obj object to test
    #@return [Boolean] is object in fact a proxy? 
    def proxy? obj
      !!(obj.instance_eval { @is_proxy })
    rescue false
    end
    module_function :proxy?

    #@param [Object] obj object to proxy
    #@return [UniqueProxy] create a unique proxy over obj
    def proxy obj
      UniqueProxy.new obj
    rescue false
    end
    module_function :proxy
  end
  
  # Simple Proxy for distinguishing between the insertions of two identical
  # objects in an order tree.  Assign a unique ID to any object passed through
  # the proxy, so you can always find the same object, even if you move it
  # around in the tree. It also enables you to tell the differen between two
  # different insertions of the same singleton object.
  class UniqueProxy < BasicObject
    class << self
      attr_accessor :verbose_inspect
    end

    # @param [Object] obj - the proxy target
    def initialize obj
      @is_proxy = true
      @obj = obj
      @uuid ||= ::SecureRandom.uuid
    end

    # @return [String] the unique ID of the proxy
    def unique_id
      @uuid
    end

    # @return [String] a string describing the proxy if UniqueProxy.verbose_inspect is not false
    #   otherwise calls #inspect on the proxied object
    def inspect
      if UniqueProxy.verbose_inspect
        "#<#{UniqueProxy}::#{@uuid} => #{@obj.inspect}>"
      else
        @obj.inspect
      end
    end
    
    # @return [String] a eval-able string to create a new proxy over this proxied object
    def to_s
      if UniqueProxy.verbose_inspect
        "proxy(#{@obj.to_s})"
      else
        @obj.to_s
      end
    end

    # Is true only if the other object has the same unique_id as self
    def equal? other
      (@uuid == other.unique_id) rescue false
    end

    # @return [Object] the unproxied target
    def orig
      @obj
    end
    
    def deproxy
      @obj
    end
    
    # Dispatches methods calls to proxy target
    def method_missing(method, *args, &block)
      @obj.__send__ method, *args, &block
    end
   
    # @private
    def !
      !@obj
    end
    
    # @private
    def == arg
      return true if @obj.nil? and arg.nil?
      @obj == arg
    end
    
    # @private
    def != arg
      @obj != arg
    end
  end
end

