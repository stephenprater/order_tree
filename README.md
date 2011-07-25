#Ordered Tree

This is a nested hash / unbalance tree structure which iterates over all of 
it's available values in insertion order.

##Like a Normal Hash?

Exactly like a normal hash.  With a standard Ruby Hash it's impossible to 
know whether or not `hash["a"]["b"]` was inserted before or after `hash["b"]["c"]`
because each individual Hash maintains it's own insertion order.

Now you can know.  If you need to.  The main thing you gain with this over an
Array is the ability to prune or transplant multiple values at the same
time by cutting on one of the branches.

##Caveat

Each value is actually stored in a proxy object which maintains a unique id.
This is necessary so that if you insert three `4`s into the tree you can tell
which one came first.  This would actually be necessary in a C implementation,
or in one based on WeakRefs, but it works okay here.

You can generally treat the OrderTree exactly like a nested hash, but be aware
that the first and last methods (as well as the #each iterator) actually return
an OrderTreeNode and not the actual object stored at that location.  (You can
get at it by using #orig on the returned value.
