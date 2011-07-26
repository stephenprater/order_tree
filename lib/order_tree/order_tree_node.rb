module OrderTree
  class OrderTreeNode < UniqueProxy
    attr_accessor :next, :prev
    attr_accessor :tree
    attr_reader :path

    def initialize obj, tree
      super(obj)
      @tree = tree
    end

    def remove
      prev_node = self.prev
      next_node = self.next
      self.next.prev = prev_node if self.next 
      self.prev.next = next_node if self.prev 

      if self.tree.root.first.equal? self
        if next_node
          self.tree.root.instance_eval do
            self.first = next_node
          end
        end
      end

      if self.tree.root.last.equal? self
        if prev_node
          self.tree.root.instance_eval do
            self.last = prev_node
          end
        end
      end

      # try this so that the node can remove
      # itself fromt he tree
      my_path = self.path
      self.tree.instance_eval do
        _delegate_hash.delete my_path.last
      end
      @path = nil
      @tree = nil
      @next = nil
      @prev = nil
      self
    end

    def before other
      (self <=> other) == -1 ? true : false
    end

    def after other
      (self <=> other) == 1 ? true : false
    end

    def <=> other
      if self.equal? other
        return 0
      else
        p, n = self.prev, self.next
        while p or n
          return 1 if p.equal? other
          return -1 if n.equal? other
          p = p.prev if p
          n = n.next if n
        end
      end
      raise ::ArgumentError, "Cannot compare #{self} and #{other} because they are not in the same tree" 
    end

    def path
      @path || self.path!
    end
    
    def path!
      @path = self.tree.root.strict_path! self
    end
  end
end
