//  Copyright © 2016 Kelan Champagne. All rights reserved.


import XCTest
@testable import Synchronized

class PerformanceTests: XCTestCase {

    /// Try to do the same stuff as `runPerformanceTest(using:)`, but without
    /// the lock, so we can get a sense of how expensive the work is by itself,
    /// e.g. the `DispatchGroup` stuff.
    func testBaseline() {
        var count = 0
        let numIterations = 100_000
        measure {
            let group = DispatchGroup()  // used to wait for all the async blocks to finish
            for _ in 0..<numIterations {
                group.enter()
                DispatchQueue.global().async {
                    count += 1
                    group.leave()
                }
            }
            group.wait()
        }
        // for fun, see how many were missed
        print("Without locking: expected=\(numIterations), actual=\(count)")
        XCTAssertNotEqual(count, numIterations)
    }

    func testUsingSemaphore() {
        measure {
            runPerformanceTest(using: DispatchSemaphore(value: 1))
        }
    }

    func testUsingQueue() {
        measure {
            runPerformanceTest(using: DispatchQueue(label: "lock"))
        }
    }

    func testUsingRWLock() {
        measure {
            runPerformanceTest(using: RWLock()!)
        }
    }

    func testUsingNSLock() {
        measure {
            runPerformanceTest(using: NSLock())
        }
    }

    func testUsingOSSpinLockable() {
        measure {
            runPerformanceTest(using: OSSpinLockable())
        }
    }

}

func runPerformanceTest(using lockingStrategy: Lockable) {
    let criticalCount = Synchronized(0, lock: lockingStrategy)
    let numIterations = 100_000
    let group = DispatchGroup()  // used to wait for all the async blocks to finish
    for _ in 0..<numIterations {
        group.enter()
        DispatchQueue.global().async {
            criticalCount.update { count in
                count += 1
            }
            group.leave()
        }
    }
    group.wait()
    // make sure we got the correct count
    XCTAssertEqual(numIterations, criticalCount.unsafeGet())
}
