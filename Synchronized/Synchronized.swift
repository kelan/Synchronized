//  Copyright © 2016 Kelan Champagne. All rights reserved.


import Foundation


// MARK: - Synchronized

/// Holds a value, and makes sure that it is only accessed while a lock is held.
public final class Synchronized<T> {
    private var value: T
    private var lock: Lockable

    /// - parameter lock: Lets you choose the type of lock you want.
    public init(_ value: T, lock: Lockable = DispatchSemaphore(value: 1)) {
        self.value  = value
        self.lock = lock
    }

    /// Get read-write access to the synchronized resource
    ///
    /// Pass a closure that takes the old value as an `inout` argument, so
    /// you can use that when determining the new value (which you set by just
    /// mutating that closure parameter.
    /// - note: The write lock is held during the whole execution of the closure.
    public func update(block: (inout T) throws -> Void) rethrows {
        try lock.performWithWriteLock {
            try block(&value)
        }
    }

    /// Get read-only access to the synchronized resource
    ///
    /// You can do a calculation on the value to return some derived value.
    /// REVIEW: Should this be called `with()`?
    public func use<R>(block: (T) throws -> R) rethrows -> R {
        return try lock.performWithReadLock {
            return try block(value)
        }
    }

    /// - note: If you get a reference type, you shouldn't use it to modify the value
    ///     TODO: How can we enforce that?
    /// I want to return a copy of the value here, but if it's a reference type, then I can't guarantee the caller doesn't use the result to modify the referenced object…
    /// Maybe this would make more sense if value were constrainted to be a struct?
    /// Pehaps a different "flavor" of AtomicBox (with different methods) would be useful for a struct?
    /// TODO: rename to `.copy()` or `.read()`?
    /// TODO: Is there such thing as a "safeGet"?
    public func unsafeGet() -> T {
        return lock.performWithReadLock {
            return value
        }
    }
    
}


// MARK: - Lockable

/// This lets you provide different locking implementations for the
/// `Synchronized` resource.
public protocol Lockable {
    func performWithReadLock<T>(_ block: () throws -> T) rethrows -> T
    func performWithWriteLock<T>(_ block: () throws -> T) rethrows -> T
}


/// Make a `DispatchSemaphore` be Lockable
extension DispatchSemaphore: Lockable {

    public func performWithReadLock<T>(_ block: () throws -> T) rethrows -> T {
        wait()
        defer { signal() }
        return try block()
    }

    public func performWithWriteLock<T>(_ block: () throws -> T) rethrows -> T {
        wait()
        defer { signal() }
        return try block()
    }

}


/// Make a `DispatchQueue` be Lockable
/// - note: You *MUST* use a serial queue for this.  Don't use a global/concurrent queue!
extension DispatchQueue: Lockable {

    public func performWithReadLock<T>(_ block: () throws -> T) rethrows -> T {
        return try sync(execute: block)
    }

    public func performWithWriteLock<T>(_ block: () throws -> T) rethrows -> T {
        return try sync(execute: block)
    }
    
}


// MARK: RWLock

/// Use a `pthread_rwlock` to allow multiple concurrent reads to
/// the `Synchronized` resource, but only allow a single writer.
///
/// Based on https://github.com/PerfectlySoft/Perfect-Thread/blob/master/Sources/Threading.swift#L151
public final class RWLock: Lockable {

    private var lock = pthread_rwlock_t()

    public init?() {
        let res = pthread_rwlock_init(&lock, nil)
        if res != 0 {
            assertionFailure("rwlock init failed")
            return nil
        }
    }

    deinit {
        let res = pthread_rwlock_destroy(&lock)
        assert(res == 0, "rwlock destroy failed")
    }

    // Primitives

    public func lockForReading() {
        pthread_rwlock_rdlock(&lock)
    }

    public func lockForWriting() {
        pthread_rwlock_wrlock(&lock)
    }

    public func unlock() {
        pthread_rwlock_unlock(&lock)
    }


    // Lockable

    public func performWithReadLock<T>(_ block: () throws -> T) rethrows -> T {
        lockForReading()
        defer { unlock() }
        return try block()
    }

    public func performWithWriteLock<T>(_ block: () throws -> T) rethrows -> T {
        lockForWriting()
        defer { unlock() }
        return try block()
    }

}


// MARK: NSLock

/// Make a `NSLock` be Lockable
extension NSLock: Lockable {

    public func performWithReadLock<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }

    public func performWithWriteLock<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }

}


// MARK: OSSpinLock

/// Use an `OSSpinLock` as the Locking strategy
/// - note: Because `OSSpinLock()` isn't a class, we can't simple make an
///     extension on it here
class OSSpinLockable: Lockable {

    private var spinlock = OSSpinLock()

    public func performWithReadLock<T>(_ block: () throws -> T) rethrows -> T {
        OSSpinLockLock(&spinlock)
        defer { OSSpinLockUnlock(&spinlock) }
        return try block()
    }

    public func performWithWriteLock<T>(_ block: () throws -> T) rethrows -> T {
        OSSpinLockLock(&spinlock)
        defer { OSSpinLockUnlock(&spinlock) }
        return try block()
    }
    
}
