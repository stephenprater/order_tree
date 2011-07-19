module OrderTree
  #Array subclass which stores the insertion order in an OrderTree
  class OrderStore < Array 
    attr_accessor :root
    
    #@param [OrderTree] tree the tracked OrderTree
    def initialize(tree)
      @root = tree 
    end

    def to_s
      "#<#{self.class}:#{'0x%x' % self.__id__ << 1}>"
    end
  end
end
