require 'spec_helper'

require 'pp'

require 'order_tree'

describe OrderTree::UniqueProxy do
  it "can tell apart things that are the same" do
    (4 == 4).should eq true
    (4.equal? 4).should eq true #because fixnums are really the same object
    a = OrderTree::UniqueProxy.new(4)
    b = OrderTree::UniqueProxy.new(4)
    c = OrderTree::UniqueProxy.new(5)
    (a == b).should eq true
    (!c).should eq false
    (c != a).should eq true
    (a.equal? b).should eq false
    (a.orig.equal? b.orig).should eq true
  end

  it "can retrieve the unique id" do
    a = OrderTree::UniqueProxy.new(4)
    b = OrderTree::UniqueProxy.new(4)
    a.unique_id.should_not eq b.unique_id
  end

  it "can identify a proxy" do
    Object.send :include, OrderTree::ProxyOperator
    a = OrderTree::UniqueProxy.new(5)
    debugger
    (proxy? a).should be_true
    (proxy? 5).should be_false
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

    @testhash_insertion = { 
      :to => {
        :d => 4,
        :e => 4,
        :to_to => {
          :f => 5,
          :g => 6,
          :h => 7,
        }
      },
      :from => {
        :a => {
          :b => 4,
          :c => 4,
        }
      }
    }
    
    @order = [[:from, :a, :b],
              [:from, :a, :c],
              [:from, :a],
              [:from],
              [:to, :d],
              [:to, :e],
              [:to, :to_to, :f],
              [:to, :to_to, :g],
              [:to, :to_to, :h],
              [:to, :to_to],
              [:to]]
  end

  it "initializes with a hash" do
    ot = OrderTree::OrderTree.new(@testhash)
    ot2 = OrderTree::OrderTree.new(@testhash_insertion)
  end

  it "can retrieve based on path or nest" do
    ot = OrderTree::OrderTree.new(@testhash)
    ot2 = OrderTree::OrderTree.new(@testhash_insertion)
    [ot, ot2].map do |t|
      t[:from][:a][:c].should eq 4
      t[:from, :a, :c].should eq 4
    end
  end

  it "can set based on path or nest" do
    ot = OrderTree::OrderTree.new(@testhash)
    ot2 = OrderTree::OrderTree.new(@testhash_insertion)
    [ot, ot2].map do |t|
      t[:from][:a][:d] = 4
      t[:from, :a, :d].should eq 4
      t[:from, :a, :e] = 6
      t[:from][:a][:e].should eq 6
    end
  end

  it "remember the order" do
    ot = OrderTree::OrderTree.new(@testhash)
    ot2 = OrderTree::OrderTree.new(@testhash_insertion)
    ot.each_path.to_a.should eq @order
    ot2.each_path.to_a.should_not eq @order
  end

  it "does not reify the hash on access" do
    ot = OrderTree::OrderTree.new
    lambda do 
      ot[:a, :b, :c] = 4
    end.should raise_error NoMethodError
  end

  it "remembers the order after initialize" do
    ot = OrderTree::OrderTree.new
    order_paths = [[:a],
                   [:a, :a1],
                   [:a, :a2],
                   [:b],
                   [:b, :c],
                   [:b, :c, :d]]
    order_paths.map do |v|
      if [[:a], [:b], [:b, :c]].include? v
        ot[*v] = {}
      else
        ot[*v] = 4
      end
    end
    ot.each_path.to_a.should eq order_paths
  end

  it "does == comparison" do
    ot = OrderTree::OrderTree.new @testhash
    ot2 = OrderTree::OrderTree.new @testhash

    ot.first.should eq ot2.first #because the underlying objects are compared
    (ot == ot2).should be_true #each order and == on the object
    ot.equal?(ot2).should be_false

    (ot.first.equal? ot2.first).should be_false
  end

  it "does != comparison" do
    ot = OrderTree::OrderTree.new @testhash
    ot2 = OrderTree::OrderTree.new @testhash_insertion

    (ot != ot2).should be_true
  end

  it "does leaf/node equality with contents_equal?" do
    ot = OrderTree::OrderTree.new @testhash
    ot2 = OrderTree::OrderTree.new @testhash_insertion
    (ot.contents_equal? ot2).should be_true
  end
     
  it "overwriting a key moves it to the end of the order" do
    ot = OrderTree::OrderTree.new
    ot[:a] = 4
    ot[:b] = 4
    ot.each_path.to_a.should eq [[:a], [:b]]
    ot[:a] = 5
    ot.each_path.to_a.should eq [[:b], [:a]]
  end

  it "overwriting a nested keys moves to the end of the order" do
    ot = OrderTree::OrderTree.new( {:a => { :b => 4}, :c => 5})
    ot.each_path.to_a.should eq [[:a, :b], [:a], [:c]]
    ot[:a,:b] = 5
    ot.each_path.to_a.should eq [[:a], [:c], [:a, :b]]
  end

  it "returns a default when the key doesn't exist" do
    ot = OrderTree::OrderTree.new @testhash
    ot.default = "foo"
    ot[:to, :foo].should eq "foo"
  end

  it "can find the path for value" do
    ot = OrderTree::OrderTree.new @testhash
    ot.path(7).should eq [:to, :to_to, :h]
    ot.path(8).should be_nil

    lambda do
      ot.path!(7).should eq [:to, :to_to, :h]
      ot.path!(8)
    end.should raise_error OrderTree::PathNotFound
  end

  it "can run enumerable methods which depend on <=>" do
    ot = OrderTree::OrderTree.new @testhash
    ot.max.should eq ot[*ot.path(ot.last)]
    ot.min.should eq ot.first
    ot.sort.should eq ot.order
  end
end
