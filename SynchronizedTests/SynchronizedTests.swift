//
//  SynchronizedTests.swift
//  SynchronizedTests
//
//  Created by Kelan Champagne on 8/29/16.
//  Copyright © 2016 Kelan Champagne. All rights reserved.
//

import XCTest
@testable import Synchronized


class SynchronizedTests: XCTestCase {

    func testSuperSimple() {
        let criticalString = Synchronized("test")
        let uppercasedString = criticalString.use { $0.uppercased() }
        print(uppercasedString)
        XCTAssertEqual(uppercasedString, "TEST")
    }

    /// This tests that Synchronized protects against concurrnet mutation
    func testConcurrentMutation() {
        let criticalCount = Synchronized(0)
        let numIterations = 10
        let group = DispatchGroup()
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
        let numIterations = 10
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
    
}
