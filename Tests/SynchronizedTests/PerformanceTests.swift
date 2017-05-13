//  Copyright © 2016 Kelan Champagne. All rights reserved.


import XCTest
@testable import Synchronized

class PerformanceTests: XCTestCase {

    func testUsingSemaphore() {
        measure {
            performTest(using: DispatchSemaphore(value: 1))
        }
    }

    func testUsingQueue() {
        measure {
            performTest(using: DispatchQueue(label: "lock"))
        }
    }

    func testUsingRWLock() {
        measure {
            performTest(using: RWLock()!)
        }
    }

}

func performTest(using lockingStrategy: Lockable) {
    let criticalCount = Synchronized(0, lock: lockingStrategy)
    let numIterations = 100000
    let group = DispatchGroup()  // used to wait for all the async blocks to finish
    for _ in 0..<numIterations {
        group.enter()
        DispatchQueue.global().async {
            criticalCount.update { count in
                let original = count
                count = original + 1
            }
            group.leave()
        }
    }
    group.wait()
}
