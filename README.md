
# Synchronized


A Swift micro-framework to help use properties in a thread-safe way.

Based on an idea I wrote about [in this blog post](http://kelan.io/2016/synchronized-wrapper-in-swift/)


I've been using it some small projects, and find it useful enough to share.


## Installation

It seems silly to add a whole dynamic `.framework` to your app just to use this.
I'd recommend just grabbing the single `Synchronized.swift` file, and adding that to
your project directly.

Or, you can use Swift Package Manager.  Let's hope Xcode gets support for that soon.


## Caveats

* This doesn't fully guarantee thread-safety for reference types, if you hold
  a reference to the `Synchronized` resource that escapes the closure, and then
  access/mutate it.  But this at least makes it harder to do that.

