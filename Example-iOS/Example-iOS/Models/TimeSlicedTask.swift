//
//  TimeSlicedTask.swift
//  Example-iOS
//
//  Created by Prachi Gauriar on 8/28/2016.
//  Copyright © 2016 Ticketmaster Entertainment, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Task


/// The errors that a `TimeSlicedTask` can raise while executing.
enum TimeSlicedTaskError : Error {
    /// Indicates that a random error occurred.
    case randomError
}


/// This is a very simple demo subclass of `TSKTask`. Each `TimeSlicedTask` instance has a total amount of time
/// required to complete. When the task is executed, it will run in small time slices and update its total
/// progress until it is complete. See the `main` method implementatin for more details.
class TimeSlicedTask : TSKTask {
    /// The amount of time the task has run.
    private(set) var timeTaken: TimeInterval = 0

    /// The total amount of time the task must run before being complete.
    private(set) var timeRequired: TimeInterval = 0

    private var _probabilityOfFailure: Double = 0

    /// The probability that the task will fail. This should be a value between 0.0 and 1.0.
    var probabilityOfFailure: Double {
        get { return _probabilityOfFailure }
        set { _probabilityOfFailure = max(0.0, min(newValue, 1.0)) }
    }

    /// The task’s progress (between 0.0 and 1.0, inclusive)
    ///
    /// If the task is in the executing state, returns timeTaken / timeRequired. If it is in the
    /// finished state, returns 1.0. Otherwise returns 0.0.
    var progress: Double {
        if isExecuting {
            return min(timeTaken / timeRequired, 1.0);
        }

        return isFinished ? 1.0 : 0.0;
    }

    /// A block that is executed every time the task makes progress. This may be used to update a UI.
    var progressBlock: ((TimeSlicedTask) -> ())?


    override convenience init(name: String?) {
        self.init(name: name, timeRequired: 0.0)
    }


    init(name: String?, timeRequired: TimeInterval) {
        self.timeRequired = timeRequired
        super.init(name: name)
    }


    override func main() {
        // Run in 1/8s time slices
        let kTimeSliceInterval: TimeInterval = 1 / 8;

        let shouldFail = randomDouble() < probabilityOfFailure
        let failureTime: TimeInterval = randomDouble() * timeRequired

        timeTaken = 0
        while timeTaken < timeRequired {
            guard isExecuting else {
                return
            }

            if shouldFail && timeTaken > failureTime {
                fail(with: TimeSlicedTaskError.randomError)
                return
            }

            let start = Date()
            Thread.sleep(forTimeInterval: kTimeSliceInterval)
            timeTaken += Date().timeIntervalSince(start)

            if let progressBlock = progressBlock {
                progressBlock(self)
            }
        }

        if shouldFail {
            // If the failure was supposed to occur during the last time slice, fail here
            fail(with: TimeSlicedTaskError.randomError)
        } else {
            finish(with: nil)
        }
    }
}
