/*

 This shows some basic usage of a Synchronized<T> resource.

 */
import Synchronized  // <-- If you get an error here, build the `Synchronized` scheme
import Dispatch
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true



// MARK: - Most basic usage, just with a local variable

let criticalString = Synchronized<String>("test")
let uppercasedString = criticalString.use { $0.uppercased() }
print("uppercased:", uppercasedString)



// MARK: - More realistic usage, in a class property

class C {
    let criticalCount = Synchronized<Int>(0)

    func incrementOnUnknownThread() {
        criticalString.update { count in
            count += 1
        }
    }
}




// MARK: - Concurrent mutations
// The following show an example of a race (exacerbased by
// adding a `sleep()` that Synchronized<T> is intended to
// help you avoid.

let numIterations = 10

// (1) Showing an example of the kind of problem that Synchronized<T> can solve.
if false {
    var unsafeCriticalCount: Int = 0
    let group1 = DispatchGroup()
    for _ in 0..<numIterations {
        group1.enter()
        DispatchQueue.global().async {
            // BAD: This is some racy code
            let original = unsafeCriticalCount
            usleep(10)
            unsafeCriticalCount = original + 1
            group1.leave()
        }
    }
    group1.wait()
    print("1) expected: \(numIterations), actual: \(criticalCount.unsafeGet())")
}


// (2) Showing concurrent mutations
if false {
    let criticalCount2 = Synchronized(0)
    let group2 = DispatchGroup()
    for _ in 0..<numIterations {
        group2.enter()
        DispatchQueue.global().async {
            criticalCount2.update { count in
                let original = count
                usleep(10)
                count = original + 1
            }
            group2.leave()
        }
    }
    group2.wait()
    print("(2) expected: \(numIterations), actual: \(criticalCount2.unsafeGet())")
}


// (3) Use a different locking strategy
if false {
    let criticalCount3 = Synchronized(0, lock: DispatchQueue(label: "lock"))
    let group3 = DispatchGroup()
    for _ in 0..<numIterations {
        group3.enter()
        DispatchQueue.global().async {
            criticalCount3.update { count in
                let original = count
                usleep(10)
                count = original + 1
            }
            group3.leave()
        }
    }
    group3.wait()
    print("(3) expected: \(numIterations), actual: \(criticalCount3.unsafeGet())")
}

