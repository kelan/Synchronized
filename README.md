
# Synchronized<T>

A Swift genric wrapper type to help enforce thread-safe usage of stored
properties.

This is an idea that started with a [post on my
blog](http://kelan.io/2016/synchronized-wrapper-in-swift/), and I followed up
with a [discussion about the Locking protocol](http://kelan.io/2017/swift-synchronized-locking).


## Current Status

* I've been using it some small projects, and find it useful enough to share.

## Example Usage

```swift
class C {
    private let criticalCount = Synchronized<Int>(0)

    /// This might be called on any thread, and we want to increment the
    /// `criticalCount`, without introducing a race condition.
    func incrementOnUnknownThread() {
        criticalCount.update { count in
            count += 1
        }
    }
}
```

### Available Locking Strategies

* `DispatchSemaphore`
* `DispatchQueue`
* `NSLock`
* `pthread_rwlock_t`


## Installation

I don't have a `Cartfile` because it seems silly to add a whole dynamic
`.framework` to your app just to use this.  Instead, I'd recommend just grabbing
the single `Synchronized.swift` file, and adding that to your project directly.

I did add a `Package.swift` file for Swift Package Manager, just for fun.  Let's
hope Xcode gets better support for that soon!


## ⚠️ Caveats

* This doesn't fully guarantee thread-safety for reference types, if you hold
  a reference to the `Synchronized` resource that escapes the closure, and then
  access/mutate it.  But this at least makes it harder to do that.
* This hasn't been thoroughly tested yet, or used in serious production code,
  but I do think the idea is sound, so more testing and usage would do it good.


## Further Ideas (TODO)

* Add more locking strategies
    * [`os_unfair_lock`](https://developer.apple.com/documentation/os/os_unfair_lock)
    * `pthread_mutex_t` directly?
* Refine the naming of the `update()` and `use()` methods`
    * Some ideas are:
        * for the `use()` method: `read()`, `with()`
        * for the `update()` method: `write()`, `mutate()`
* Further testing, especially performance testing of the various locking strategies

## Similar Projects

I didn't know about this when I wrote this initially, but I noticed something
similar to this, in [PMHTTP](https://github.com/postmates/PMHTTP), named
[QueueConfined](https://github.com/postmates/PMHTTP/blob/master/Sources/QueueConfined.swift).
But that one doesn't have the ability to change the locking mechanism (it always
uses a serial queue).

