//
//  TSKTaskTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/3/14.
//  Copyright (c) 2014 Two Toasters, LLC.
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

#import "TSKRandomizedTestCase.h"


@interface TSKTaskTestCase : TSKRandomizedTestCase

- (void)testInit;

@end


@implementation TSKTaskTestCase

- (void)testInit
{
    TSKTask *task = [[TSKTask alloc] init];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");

    NSString *notName = UMKRandomUnicodeString();
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNotEqualObjects(task.name, notName, @"name not set correctly");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state not set to default");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKTask alloc] initWithName:name];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, name, @"name not set to default");
    XCTAssertNotEqualObjects(task.name, notName, @"name not set correctly");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state not set to default");

    task = [[TSKTask alloc] initWithName:nil];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
}


- (void)testGraph
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTask *task = [[TSKTask alloc] init];
    [graph addTask:task prerequisites:nil];

    XCTAssertEqual(graph, task.graph, @"graph not set properly");
    XCTAssertEqualObjects(task.prerequisiteTasks, [NSSet set], @"prereqs not empty");
    XCTAssertEqualObjects(task.dependentTasks, [NSSet set], @"dependents not empty");

    TSKTask *dependent = [[TSKTask alloc] init];
    [graph addTask:dependent prerequisites:task, nil];

    XCTAssertEqualObjects(task.dependentTasks, [NSSet setWithObject:dependent], @"dependents not set properly");
    XCTAssertEqualObjects(dependent.prerequisiteTasks, [NSSet setWithObject:task], @"prereqs not set property");

    XCTAssertEqual(dependent.state, TSKTaskStatePending, @"dependent state not set to pending");
}


- (void)testStart
{
    XCTestExpectation *startExpectation = [self expectationWithDescription:@"task started"];
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
        [startExpectation fulfill];
    }];

    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");

    [task start];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)testFinish
{
    NSString *resultString = UMKRandomUnicodeString();
    TSKTask *task = [[TSKTask alloc] init];

    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];
    [task start];
    [task finishWithResult:resultString];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
        XCTAssertEqual(task.result, resultString, @"result not set correctly");
    });
}


- (void)testFail
{
    NSError *error = [NSError errorWithDomain:UMKRandomUnicodeString()
                                         code:12345
                                     userInfo:nil];
    TSKTask *task = [[TSKTask alloc] init];

    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];
    [task start];
    [task failWithError:error];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqual(task.state, TSKTaskStateFailed, @"state  is not failed");
        XCTAssertEqual(task.error, error, @"error not returned correcctly");
    });
}


- (void)testRetry
{
    TSKTask *task = [[TSKTask alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];

    [task retry];
    XCTAssertEqual(task.state, TSKTaskStateReady, @"retry executed from invalid state");

    [task start];
    [task failWithError:nil];
    [task retry];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");

        [task finishWithResult:nil];
        XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    });
}


- (void)testCancel
{
    NSLock *didCancelLock = [[NSLock alloc] init];

    XCTestExpectation *didStartExpectation = [self expectationWithDescription:@"main executed"];

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        // Confirms that task is mid-execution when -cancel is called
        [didStartExpectation fulfill];

        // Pause for lock to ensure this executes after -cancel
        [didCancelLock lock];
        [task finishWithResult:UMKRandomAlphanumericString()];
        [didCancelLock unlock];
    }];

    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];

    // Lock to ensure state transitions to cancelled before -finishWithResult: is called
    [didCancelLock lock];
    [task start];

    [self waitForExpectationsWithTimeout:1 handler:nil];

    // Call cancel only after main has been entered
    [task cancel];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"state is not cancelled");
    [didCancelLock unlock];

    // Block is waiting for lock and executes
    // Test pauses to ensure block is finished and -finishWithResult: is called on task
    [didCancelLock lock];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"finish is honored on cancelled task");
    XCTAssertNil(task.result, @"finish is honored on cancelled task");
    [didCancelLock unlock];


    XCTestExpectation *didStartExpectation2 = [self expectationWithDescription:@"main executed"];
    TSKBlockTask *failTask = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [didStartExpectation2 fulfill];

        // Pause to ensure state is cancelled before failWithError: is called
        [didCancelLock lock];
        [task failWithError:UMKRandomError()];
        [didCancelLock unlock];
    }];

    [graph addTask:failTask prerequisites:nil];

    [didCancelLock lock];
    [failTask start];

    // Ensure task is executing before cancel is called
    [self waitForExpectationsWithTimeout:1 handler:nil];

    [failTask cancel];
    [didCancelLock unlock];

    // Block is waiting for lock and executes
    // Test pauses to ensure block is finished and -failWithError: is called on task
    [didCancelLock lock];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"fail is honored on cancelled task");
    XCTAssertNil(task.error, @"fail is honored on cancelled task");
    [didCancelLock unlock];

}


- (void)testReset
{
    __block NSUInteger counter = 0;
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        counter++;
        if (counter == 1) {
            [task failWithError:nil];
        }
    }];

    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];

    [task start];

    sleep(1);
    XCTAssertEqual(counter, 1, @"main did not run once");
    XCTAssertEqual(task.state, TSKTaskStateFailed, @"state is not failed");

    [task reset];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");

        [task finishWithResult:nil];
        XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
        XCTAssertEqual(counter, 2, @"main did not run twice");
    });
    
}

@end


// State transitions:
//     Pending -> Ready: All of task’s prerequisite tasks are finished (-startIfReady)
//     Pending -> Cancelled: Task is cancelled (-cancel)
//
//     Ready -> Pending: Task is added to a graph with at least one prerequisite task (-didAddPrerequisiteTask)
//     Ready -> Executing: Task starts (-start)
//     Ready -> Cancelled: Task is cancelled (-cancel)
//
//     Executing -> Pending: Task is reset (-reset)
//     Executing -> Cancelled: Task is cancelled (-cancel)
//     Executing -> Finished: Task finishes (-finishWithResult:)
//     Executing -> Failed: Task fails (-failWithError:)
//
//     Cancelled -> Pending: Task is retried (-retry) or reset (-reset)
//
//     Finished -> Pending: Task is reset (-reset)
//
//     Failed -> Pending: Task is retried (-retry) or reset (-reset)

