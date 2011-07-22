require 'securerandom'

module OrderTree
  
  module ProxyOperator
    def proxy? obj
      !!(obj.instance_eval { @is_proxy })
    rescue false
    end
    module_function :proxy?
  end
  
  # Simple Proxy for distinguishing between the insertions of two identical
  # objects in an order tree.  Assign a unique ID to any object passed through
  # the proxy, so you can always find the same object, even if you move it
  # around in the tree.
  class UniqueProxy < BasicObject

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

    # Is true only if the other object has the same unique_id as self
    def equal? other
      (@uuid == other.unique_id) rescue false
    end

    # @return [Object] the unproxied target
    def orig
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
      @obj == arg
    end
    
    # @private
    def != arg
      @obj != arg
    end
  end

  class OrderTreeNode < UniqueProxy
    attr_accessor :next, :prev
    attr_accessor :tree
    attr_reader :path

    def initialize obj, tree
      super(obj)
      @tree = tree
    end

    def remove
      @path = nil
      self.next.prev = self.prev || nil 
      if self.tree.root.first == self
        self.tree.root.first = self.next
      end
      @tree = nil
      @next = nil
      @prev = nil
      self
    end

    def <=> other
      unless other.is_a? OrderTreeNode
        raise TypeError, "Can't compare OrderTreeNode with other types"
      end
      if self.equal? other
        return 0
      else
        p = self.prev
        while p
          return 1 if p.equal? other
          p = self.prev
        end
        n = self.next 
        while n
          return -1 if n.equal? other
          n = self.next
        end
      end
    end

    def path
      @path || self.path!
    end
    
    def path!
      @path = self.tree.root.strict_path self
    end
  end
end

