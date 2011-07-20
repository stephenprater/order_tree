module OrderTree
  #Array subclass which stores the insertion order in an OrderTree
  class OrderStore
    include Enumerable
    attr_accessor :root
    
    #@param [OrderTree] tree the tracked OrderTree
    def initialize(tree)
      @root = tree 
    end

    def each
      return enum_for(:each) unless block_given? 
      c = @root.first
      while c 
        yield c
        c = c.next
      end
    end

    def to_s
      "#<#{self.class}:#{'0x%x' % self.__id__ << 1}>"
    end
  end
end
