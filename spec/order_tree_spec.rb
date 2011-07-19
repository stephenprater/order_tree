require 'rspec'

require 'order_tree'

describe OrderTree::UniqueProxy do
  it "can tell apart things that are the same" do
    (4 == 4).should eq true
    (4.equal? 4).should eq true #because fixnums are really the same object
    a = OrderTree::UniqueProxy.new(4)
    b = OrderTree::UniqueProxy.new(4)
    (a == b).should eq true
    (a.equal? b).should eq false
    (a.orig.equal? b.orig).should eq true
  end

  it "can retrieve the unique id" do
    a = OrderTree::UniqueProxy.new(4)
    b = OrderTree::UniqueProxy.new(4)
    a.unique_id.should_not eq b.unique_id
  end
end

describe OrderTree::OrderTree do
   before :all do
     @testhash = {
      :from => {
        :a => {
          :b => 4,
          :c => 4,
        }
      },
      :to => {
        :d => 4,
        :e => 4,
        :to_to => {
          :f => 5,
          :g => 6,
          :h => 7,
        }
      }
    }
    
     @order = [[:from], [:from, :a], [:from, :a, :b], [:from, :a, :c],
     [:to], [:to, :d], [:to, :e], 
     [:to, :to_to], [:to, :to_to, :f], [:to, :to_to, :g], [:to, :to_to, :h]]
  end

  it "initializes with a hash" do
    ot = OrderTree::OrderTree.new(@testhash)
  end

  it "can retrieve based on path or nest" do
    ot = OrderTree::OrderTree.new(@testhash)
    ot[:from][:a][:c].should eq 4
    ot[:from, :a, :c].should eq 4
  end

  it "can set based on path or nest" do
    ot = OrderTree::OrderTree.new(@testhash)
    ot[:from][:a][:d] = 4
    ot[:from, :a, :d].should eq 4
    ot[:from, :a, :e] = 6
    ot[:from][:a][:e].should eq 6
  end

  it "remember the order" do
    ot = OrderTree::OrderTree.new(@testhash)
    debugger
    ot.order
  end
end
    
