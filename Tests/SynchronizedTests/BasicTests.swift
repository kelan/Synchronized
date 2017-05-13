//  Copyright © 2016 Kelan Champagne. All rights reserved.


import XCTest
@testable import Synchronized


class BasicTests: XCTestCase {

    /// This just tests that the APIs work as expected
    func testBasicUsage() {
        let criticalString = Synchronized("test")
        let uppercasedString = criticalString.use { $0.uppercased() }
        XCTAssertEqual(uppercasedString, "TEST")
    }

    /// This tests that Synchronized protects against concurrnet mutation, by dispatching
    /// a bunch of async blocks that each do:
    ///     read,
    ///     sleep (to exacerbate the race)
    ///     increment and write
    /// and then making sure the count ends up being incremented the correct number of times.
    func testConcurrentMutation() {
        let criticalCount = Synchronized(0)
        let numIterations = 100
        let group = DispatchGroup()  // used to wait for all the async blocks to finish
        for _ in 0..<numIterations {
            group.enter()
            DispatchQueue.global().async {
                criticalCount.update { count in
                    let original = count
                    usleep(10)
                    count = original + 1
                }
                group.leave()
            }
        }
        group.wait()
        XCTAssertEqual(criticalCount.unsafeGet(), numIterations, "Should have gotten all counts")
    }

    /// This does the same pattern as `testConcurrentMutation()`, but doesn't
    /// use a Synchronized wrapper, so it loses counts.
    func testConcurrentMutationWithoutSyncrhonizedHasProblems() {
        var count = 0
        let numIterations = 100
        let group = DispatchGroup()
        for _ in 0..<numIterations {
            group.enter()
            DispatchQueue.global().async {
                let original = count
                usleep(10)
                count = original + 1
                group.leave()
            }
        }
        group.wait()
        XCTAssertLessThan(count, numIterations, "Should have lost counts")
    }


    /// Same as `testConcurrentMutation(), but uses a DispatchQueue as the locking strategy,
    /// instead of the default DispatchSemaphore.
    func testQueueLockingStrategy() {
        let serialQueue = DispatchQueue(label: "lock")
        let criticalCount = Synchronized(0, lock: serialQueue)
        let numIterations = 100
        let group = DispatchGroup()  // used to wait for all the async blocks to finish
        for _ in 0..<numIterations {
            group.enter()
            DispatchQueue.global().async {
                criticalCount.update { count in
                    let original = count
                    usleep(10)
                    count = original + 1
                }
                group.leave()
            }
        }
        group.wait()
        XCTAssertEqual(criticalCount.unsafeGet(), numIterations, "Should have gotten all counts")
    }


    /// Same as `testConcurrentMutation(), but uses a RWLock as the locking strategy,
    /// instead of the default DispatchSemaphore.
    func testRWLockingStrategy() {
        let rwLock = RWLock()!
        let criticalCount = Synchronized(0, lock: rwLock)
        let numIterations = 100
        let group = DispatchGroup()  // used to wait for all the async blocks to finish
        for _ in 0..<numIterations {
            group.enter()
            DispatchQueue.global().async {
                criticalCount.update { count in
                    let original = count
                    usleep(10)
                    count = original + 1
                }
                group.leave()
            }
        }
        group.wait()
        XCTAssertEqual(criticalCount.unsafeGet(), numIterations, "Should have gotten all counts")
    }
    
}
