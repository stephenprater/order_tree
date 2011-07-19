require 'delegate'

module OrderTree
  
  # A unbalance tree / nested hash type structure that implements #each and returns
  # the values in the order in which they were inserted, regardless of depth
  # It can mostly be treated as a nested hash - but #each will return a #path
  # to the values it iterates
  class OrderTree < Delegator
    
    # Create a new OrderTree
    # @param [Hash] constructor - a hash literal for the initial values
    # @param [optional OrderStore] order - the order store - you will likely not need to
    #   specifiy this.
    # 
    # @note The order of insertion might not be what you would expect for multi-
    #   level hash literals. The most deeply nested values will be inserted FIRST.
    def initialize(constructor = {}, order = nil) 
      @delegate_hash = {} 
      super(@delegate_hash)
      @order = order || OrderStore.new(self)
      constructor.each_with_object(self) do |(k,v),memo|
        memo[k] = v
      end
    end
  
    # Yields each value of the OrderTree in the order in which it was
    # inserted
    # @return [Enumerator]
    # @yield [path, value] yields the path (as an array) to a value
    # @yieldparam [Array] path the path as an array
    # @yieldparam [Object] value the original object stored in the OrderTree
    def each
      return enum_for(:each) unless block_given? 
      @order.each do |v|
        yield [root.strict_path(v), v.orig]
      end
    end

    # @return [Array] the results of calling {#each}.to_a
    def order
      each.to_a
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

    # @private
    def __path val = nil, strict = false, key_path = [], &block
      op = strict ? :equal? : :==
      return true if (yield(val) unless block.nil?) or val == self
      self.__getobj__.each do |k,v|
        if (yield v unless block.nil?) or v.__send__ op, val
          key_path << k 
          break
        elsif v.respond_to? :__path, true
          if v.__path(val, strict, key_path, &block) != @order.root.default
            key_path.unshift(k)
            break
          end
        end
      end
      return @order.root.default if key_path.empty?
      key_path
    end
    private :__path
   
    # The root of the tree
    def root
      @order.root
    end

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
          return @order.root.default
        end
      end
      t
    end
    
    # @param [OrderTree] other
    # @return [true] if other.order == self.order
    # @see #order
    def == other
      begin
        other.order == self.order
      rescue NoMethodError => e
        if e.name == :order
          return false
        end
      end
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
      if t == @order.root.default
        @order.root.default
      else
        t.orig
      end
    end
    
    # Stores the value at path
    # @param [Array] path
    # @param [Object] value
    def []= *paths, value
      under = self
      paths.each do |k|
        under = under.instance_eval do
          h = self.__getobj__
          if h.has_key? k
            h[k]
          else
            break h 
          end
        end 
      end

      if value.kind_of? Hash or value.kind_of? OrderTree
        value = OrderTree.new(value, @order)
      end
      under[paths.last] = UniqueProxy.new(value)
      
      #puts "insertion of '#{value}' in #{self.to_s} -> #{@order.to_s} (id #{under[paths.last].unique_id})"
      @order << under[paths.last]
      value
    end
    alias :store :[]=
  end
end
