require 'delegate'

module OrderTree
  
  # A unbalance tree / nested hash type structure that implements #each and returns
  # the values in the order in which they were inserted, regardless of depth
  # It can mostly be treated as a nested hash - but #each will return a #path
  # to the values it iterates
  class OrderTree < Delegator

    class PathNotFound < StandardError; end

    attr_accessor :last
    attr_accessor :root
    attr_reader :first
  
    # Create a new OrderTree
    # @param [Hash] constructor - a hash literal for the initial values
    # @param [OrderTree] OrderTree - the root tree object.
    # @note The order of insertion might not be what you would expect for multi-
    #   level hash literals. The most deeply nested values will be inserted FIRST.
    def initialize(constructor = {}, root = nil) 
      @delegate_hash = {} 
      super(@delegate_hash)
      self.root = root || self 
      constructor.each_with_object(self) do |(k,v),memo|
        memo[k] = v
      end
    end

    def last= obj
      if @last.nil?
        @first = obj
        @last = obj
      else
        @last = obj
      end
    end

    # Set the default value for the tree
    # This place the default object behind a UniqueProxy. The default
    # is not remembered within the order
    # @param [Object] obj
    def default= obj
      @default = UniqueProxy.new(obj)
    end

    # Yields each path, value pair of the OrderTree in the order in which it was
    # inserted
    # @return [Enumerator]
    # @yield [path, value] yields the path (as an array) to a value
    # @yieldparam [Array] path the path as an array
    # @yieldparam [Object] value the original object stored in the OrderTree
    def each
      return enum_for(:each) unless block_given?
      ep, ev = self.each_path, self.each_value
      loop do
        yield ep.next, ev.next
      end
    end

    # @return [Array] the results of calling {#each}.to_a
    def order
      each.to_a
    end

    # @return [Array] collection of paths in insertion order
    def each_path 
      return enum_for(:each_path) unless block_given?
      c = root.first
      while c
        yield c.path
        c = c.next
      end
    end

    # @return [Array] collection ov values in insertion order
    def each_value 
      return enum_for(:each_value) unless block_given?
      c = root.first
      while c
        yield c.orig
        c = c.next
      end
    end

    # Finds the first occurence of an object in the tree
    # @param [Object] val the value to search for this is a O(n) operation
    # @param [Block] block if both a block and val are passed, the 
    #   block will be evalueated first, then the value
    # @return [Array, false, true] path to value, false if not found, or true if value == self
    # @yield [value] use the block to perform more complicated tests
    # @yieldreturn [Boolean]
    # @raises [ArgumentError] if neither a val nor block is given.
    # @note You cannot search for a nil value by passing nil as the value. You must
    #   pass a block that compares for nil
    # @note This methods does NOT guarantee that you will recieve the result
    #   in inserted order
    def path val = nil, &block
      raise ArgumentError, "requires search value or block" if val.nil? and block.nil? 
      __path val, false, [], &block
    end

    # Finds the first occurence of a specific insertion in the tree
    # @param [UniqueProxy] val the proxy object to find 
    def strict_path val = nil
      __path val, true
    end
    
    # Raises an exception if it can't determine the path
    # @see {#path}
    def path! val = nil, &block
      raise PathNotFound, "Couldn't find path to #{val} in #{self.to_s}" unless path(val, &block)
    end

    # Raises an exception if it can't find the object
    # @see {#strict_path}
    def strict_path! val = nil
      raise PathNotFound, "Couldn't find path to #{val} in #{self.to_s}" unless strict_path(val)
    end

    # @private
    def __path val = nil, strict = false, key_path = [], &block
      op = strict ? :equal? : :==
      return true if (yield(val) unless block.nil?) or self.__send__ op, val 
      self.__getobj__.each do |k,v|
        if (yield v unless block.nil?) or v.__send__ op, val
          key_path << k 
          break
        elsif v.respond_to? :__path, true
          if v.__path(val, strict, key_path, &block) != self.root.default
            key_path.unshift(k)
            break
          end
        end
      end
      return self.root.default if key_path.empty?
      key_path
    end
    private :__path
   
    # @private
    # @api Delegate
    def __getobj__
      @delegate_hash
    end

    # @private
    # @api Delegate
    def __setobj__(obj)
      @delegate_hash = obj
    end


    def to_s
      "#<#{self.class}:#{'0x%x' % self.__id__ << 1}>"
    end

    
    # @param [OrderTree] other
    # @return [true] if other.order == self.order
    # @see #order
    def == other
      return false if other.class != self.class
      begin
        other.order == self.order
      rescue NoMethodError => e
        if e.name == :order
          return false
        end
      end
    end
   
    # Returns the UniqueProxy at path.
    # @param [Array] path the path to return
    # @return [Object, Array] either OrderTree default or the path as an array
    def at *paths
      t = @delegate_hash 
      begin
        paths.each do |p|
          t = t.respond_to?(:at) ? t.at(p) : t[p]
        end
      rescue NoMethodError => e
        if e.name == :[] 
          return self.root.default
        end
      end
      t
    end

    # Return the object stored at path
    # @param [Array] path you may specify the path as either an array, or
    #   by using the nested hash syntax
    # @example
    #    obj = OrderTree.new( :first => { :second => { :third => 3 }})
    #    obj[:first, :second, :third] #=> 3
    #    obj[:first][:second][:third] #=> 3
    def [] *paths
      t = self.at *paths
      t.orig
    end
    
    # Stores the value at path
    # @param [Array] path
    # @param [Object] value
    def []= *paths, value
      under = self
      paths.each do |k|
        under = under.instance_eval do
          unless self.respond_to? :__getobj__
            raise NoMethodError, "Can't reifiy tree leaf on access to #{paths}"
          end
          h = self.__getobj__
          if h.has_key? k and k != paths.last
            h[k]
          else
            break h 
          end
        end 
      end

      if value.kind_of? Hash or value.kind_of? OrderTree
        value = OrderTree.new(value, @root)
      end
      under[paths.last] = OrderTreeNode.new(value, self)
      under[paths.last].prev = root.last if root.last
      root.last.next = under[paths.last] if root.last
      root.last = under[paths.last]

      #@order.push under[paths.last]
      
      #puts "insertion of '#{value}' in #{self.to_s} -> #{@order.to_s} (id #{under[paths.last].unique_id})"
      value
    end
    alias :store :[]=
  end
end
