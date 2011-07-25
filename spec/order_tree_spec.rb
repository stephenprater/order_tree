require 'spec_helper'

require 'pp'

require 'order_tree'

describe OrderTree::UniqueProxy do
  before :all do
    Object.send :include, OrderTree::ProxyOperator
  end

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
    a = OrderTree::UniqueProxy.new(5)
    proxy(5).should eq proxy(5)
    (proxy(5).equal? proxy(5)).should be_false
    (proxy? a).should be_true
    (proxy? 5).should be_false
  end

  it "can help you inspect and to_s proxies" do
    proxy(5).to_s.should eq "5"
    proxy(5).inspect.should eq "5"
    OrderTree::UniqueProxy.verbose_inspect = true
    p = proxy(5) 
    p.inspect.to_s.should match(/#<UniqueProxy:(.*?)\s=>\s5>/)
    p.to_s.should == "proxy(5)"
    OrderTree::UniqueProxy.verbose_inspect = false
    p2 = eval(p.to_s)
    p2.should eq p
    (p2.equal? p).should be_false
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

  it "can retrieve each pair" do
    ot = OrderTree::OrderTree.new @testhash

    ot.each_pair.with_index do |(p,v),i|
      p.should eq @order[i]
      ot[*p].should eq v
    end
  end

  it "can overwrite nodes" do
    ot = OrderTree::OrderTree.new @testhash
    ot[:from, :a, :c] = 'overwritten'
   
    new_pairs = ot.each_pair.to_a
    p,v = new_pairs.last
    p.should eq [:from, :a, :c]
    v.should eq 'overwritten'
   
    ot[:from, :a, :c] = 'overwritten again'

    p.should eq [:from, :a, :c]
    ot[:from, :a, :c].should eq 'overwritten again'

    new_pairs = ot.each_pair.to_a
    p,v = new_pairs.first
    p.should eq [:from, :a, :b]
    v.should eq 4

    p,v = new_pairs[3]
    p.should eq [:to, :d]
    v.should eq 4
  end

  it "does == comparison" do
    ot = OrderTree::OrderTree.new @testhash
    ot2 = OrderTree::OrderTree.new @testhash

    ot.first.should eq ot2.first #because underlying objects are compared 
    (ot == ot2).should be_true #each order and == on the object
    ot.equal?(ot2).should be_false #we're comparing the proxies here

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

  it "does not double proxy the default" do
    ot = OrderTree::OrderTree.new @testhash
    (proxy? ot.default).should be_true
    (proxy? ot[:foobar]).should be_false
    (proxy? ot[:to, :to_to, :no_key]).should be_false
  end

  it "returns a default when the key doesn't exist" do
    ot = OrderTree::OrderTree.new @testhash
    ot.default = "foo"
    ot[:to, :foo].should eq "foo"

    #copies it to nested levels
    ot.default = "bar"
    ot[:to, :foo].should eq "bar"
    
    ot[:to, :to_to, :no_key].should eq "bar"

    # does't matter how deep i look
    ot[:foo, :bar, :foo, :monkey].should eq "bar"
  end

  it "can find the path for value" do
    ot = OrderTree::OrderTree.new @testhash
    ot.path(7).should eq [:to, :to_to, :h]
    ot.path(8).should be_nil

    lambda do
      ot.path!(7).should eq [:to, :to_to, :h]
      ot.path!(8)
    end.should raise_error OrderTree::OrderTree::PathNotFound
  end

  it "can prune the tree" do
    ot = OrderTree::OrderTree.new @testhash
    ot.default = "bob"
    ot.delete :from, :a, :b
    ot[:from, :a, :b].should eq "bob"

    to_to = ot.at :to, :to_to
    to_to.remove
    
    ot[:to, :to_to].should eq "bob"
  end

  it "can find the path for a node object" do
    ot = OrderTree::OrderTree.new @testhash
    lambda do
      ot.strict_path(7)
    end.should raise_error ArgumentError

    seven_node = ot.at *ot.path(7)
    ot.strict_path(seven_node).should eq [:to, :to_to, :h]
   
    seven_node.remove
    ot.strict_path(seven_node).should be_nil
    #this is the internal call that it uses - it's just here for completeness
    lambda do
      ot.strict_path!(seven_node)
    end.should raise_error OrderTree::OrderTree::PathNotFound
  end

  it "can run enumerable methods which depend on <=>" do
    ot = OrderTree::OrderTree.new @testhash
    ot.max.should eq ot.last 
    ot.min.should eq ot.first
    ot.sort.should eq ot.each_value.to_a

    # roundabout
    ot.max.should eq ot[*ot.strict_path!(ot.last)]
    ot.min.should eq ot[*ot.strict_path!(ot.first)]
  end

  it "can tell you about insertion order, natch" do
    ot = OrderTree::OrderTree.new @testhash
    ot2 = OrderTree::OrderTree.new @testhash_insertion
    
    (ot.at(:from, :a, :c).before(ot.at(:from, :a, :b))).should be_false
    (ot.at(:from, :a, :b).before(ot.at(:to, :d))).should be_true

    (ot.at(:from, :a, :c).after(ot.at(:from, :a, :b))).should be_true
    (ot.at(:to, :e).after(ot.at(:from, :a, :b))).should be_true

    #this probably is only possible if you're doing this.
    (ot.at(:from, :a, :b) <=> ot.at(:from, :a, :b)).should eq 0
  end

  it "can't compare nodes across trees" do
    ot = OrderTree::OrderTree.new @testhash
    ot2 = OrderTree::OrderTree.new @testhash_insertion
    
    lambda do
      ot.at(:from, :a, :c).before(ot2.at(:from, :a, :b))
    end.should raise_error ArgumentError
  end

  it "can run regular enumerable methods" do
    # i'm not going to try all of these, just the one i know
    # i didn't define.
    ot = OrderTree::OrderTree.new @testhash
    ot.each_cons(3).with_index do |v,idx|
      v.collect { |e| e.path }.should eq @order[idx..idx+2]
    end
  end
end
