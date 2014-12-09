//
//  TSKGraphTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/4/14.
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


@interface TSKGraphTestCase : TSKRandomizedTestCase

- (void)testInit;
- (void)testAddTasks;
- (void)testAddTaskErrorCases;
- (void)testOperationQueue;
- (void)testHasUnfinishedTasks;
- (void)testHasFailedTasks;
- (void)testStartNoPrerequisites;
- (void)testStartOnePrerequisite;
- (void)testStartMultiplePrequisites;
- (void)testStartMultipleDependents;
- (void)testRetry;
- (void)testCancel;

@end


@implementation TSKGraphTestCase

- (void)testInit
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    XCTAssertNotNil(graph, @"returns nil");
    XCTAssertEqualObjects(graph.allTasks, [NSSet set]);
    XCTAssertEqualObjects(graph.name, ([NSString stringWithFormat:@"TSKGraph %p", graph]), @"name not set to default");
    XCTAssertNotNil(graph.operationQueue, @"operation queue not set to default");
    XCTAssertEqualObjects(graph.operationQueue.name, ([NSString stringWithFormat:@"com.twotoasters.TSKGraph.TSKGraph %p", graph]), @"name not set to default");

    NSString *graphName = UMKRandomUnicodeString();
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    graph = [[TSKGraph alloc] initWithName:graphName operationQueue:queue];
    XCTAssertNotNil(graph, @"returns nil");
    XCTAssertEqualObjects(graph.allTasks, [NSSet set]);
    XCTAssertEqualObjects(graph.name, graphName, @"name not set properly");
    XCTAssertEqual(graph.operationQueue, queue, @"operation queue not set properly");
}


- (void)testAddTasks
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTask *task = [[TSKTask alloc] init];
    [graph addTask:task prerequisites:nil];
    XCTAssertEqualObjects([graph prerequisiteTasksForTask:task], [NSSet set], @"prereqs not set");
    XCTAssertEqualObjects([graph dependentTasksForTask:task], [NSSet set], @"prereqs not set");

    TSKTask *dependent = [[TSKTask alloc] init];
    [graph addTask:dependent prerequisites:task, nil];

    XCTAssertEqualObjects([graph prerequisiteTasksForTask:dependent], [NSSet setWithObject:task], @"prereqs not set property");
    XCTAssertEqualObjects([graph dependentTasksForTask:task], [NSSet setWithObject:dependent], @"prereqs not set property");
    XCTAssertEqualObjects([graph allTasks], ([NSSet setWithObjects:task, dependent, nil]), @"all tasks not set property");
    XCTAssertEqualObjects([graph tasksWithNoPrerequisiteTasks], ([NSSet setWithObject:task]), @"tasksWithNoPrerequisiteTasks not set correctly");
    XCTAssertEqualObjects([graph tasksWithNoDependentTasks], ([NSSet setWithObject:dependent]), @"tasksWithNoDependentTasks not set correctly");
}


- (void)testAddTaskErrorCases
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTask *task = [[TSKTask alloc] init];
    [graph addTask:task prerequisites:nil];
    XCTAssertThrows([graph addTask:task prerequisites:nil], @"adding a task to the same graph twice does not throw an exception");

    TSKGraph *otherGraph = [[TSKGraph alloc] init];
    XCTAssertThrows([otherGraph addTask:task prerequisites:nil], @"adding a task to a second graph does not throw an exception");

    TSKTask *prerequisiteTask = [[TSKTask alloc] init];
    TSKTask *dependentTask = [[TSKTask alloc] init];

    XCTAssertThrows(([graph addTask:dependentTask prerequisites:prerequisiteTask, nil]), @"graph allows a task to be added before its prerequisite is added");
}


- (void)testOperationQueue
{
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] initWithOperationQueue:operationQueue];
    XCTestExpectation *testDidRunExpectation = [self expectationWithDescription:@"test for operation queue did run"];

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        XCTAssertEqual(operationQueue, [NSOperationQueue currentQueue], @"task not executing on correct queue");
        [testDidRunExpectation fulfill];
    }];
    [graph addTask:task prerequisites:nil];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)testHasUnfinishedTasks
{
// NOTE This property is also tested in other methods to test in other scenarios (e.g., retry, cancel)
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self taskWithLock:willFinishLock];
    [graph addTask:task prerequisites:nil];

    [self expectationForNotification:kTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(graph.hasUnfinishedTasks, @"hasUnfinishedTasks is false");

    [self expectationForNotification:kTaskDidFinishNotification object:task handler:nil];
    [willFinishLock unlock];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(graph.hasUnfinishedTasks, @"hasUnfinishedTasks is true");

    graph = [[TSKGraph alloc] init];
    task = [self taskWithLock:nil failsWithError:nil];
    [graph addTask:task prerequisites:nil];

    [self expectationForNotification:kTaskDidFailNotification object:task handler:nil];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(graph.hasUnfinishedTasks, @"hasUnfinishedTasks is false");
}


- (void)testHasFailedTasks
{
// NOTE This property is also tested in other methods to test in other scenarios (e.g., retry, cancel)
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self taskWithLock:willFinishLock failsWithError:nil];
    [graph addTask:task prerequisites:nil];

    [self expectationForNotification:kTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(graph.hasFailedTasks, @"hasFailedTasks is true");

    [self expectationForNotification:kTaskDidFailNotification object:task handler:nil];
    [willFinishLock unlock];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(graph.hasFailedTasks, @"hasFailedTasks is false");

    graph = [[TSKGraph alloc] init];
    task = [self taskWithLock:nil];
    [graph addTask:task prerequisites:nil];

    [self expectationForNotification:kTaskDidFinishNotification object:task handler:nil];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(graph.hasFailedTasks, @"hasFailedTasks is true");
}


- (void)testStartNoPrerequisites
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self task];
    [graph addTask:task prerequisites:nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, "state is not ready");

    [self expectationForNotification:kTaskDidStartNotification object:task handler:nil];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateExecuting, "state is not executing");
}


- (void)testStartOnePrerequisite
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self taskWithLock:willFinishLock];
    TSKTestTask *dependentTask = [self taskWithLock:willFinishLock];
    [graph addTask:task prerequisites:nil];
    [graph addTask:dependentTask prerequisites:task, nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:kTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task starts
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:kTaskDidFinishNotification object:task handler:nil];
    [self expectationForNotification:kTaskDidStartNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // First task is waiting for lock and finishes
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is not true");

    [self expectationForNotification:kTaskDidFinishNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // Dependent task is waiting for lock and finishes
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(dependentTask.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is true");
    [willFinishLock unlock];
}


- (void)testStartMultiplePrequisites
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task1 = [self taskWithLock:willFinishLock];
    TSKTestTask *task2 = [self taskWithLock:nil];
    TSKTestTask *dependentTask = [self taskWithLock:willFinishLock];
    [graph addTask:task1 prerequisites:nil];
    [graph addTask:task2 prerequisites:nil];
    [graph addTask:dependentTask prerequisites:task1, task2, nil];

    XCTAssertEqual(task1.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(task2.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:kTaskDidStartNotification object:task1 handler:nil];
    [self expectationForNotification:kTaskDidFinishNotification object:task2 handler:nil]; // task2 has no lock, so it will finish
    [willFinishLock lock];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task1 starts and task2 finishes
    XCTAssertEqual(task1.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(task2.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:kTaskDidFinishNotification object:task1 handler:nil];
    [self expectationForNotification:kTaskDidStartNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // task1 is waiting for lock and finishes, then dependentTask begins executing
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task1.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(task2.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is not true");

    [self expectationForNotification:kTaskDidFinishNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    [self waitForExpectationsWithTimeout:1 handler:nil];  // dependentTask is waiting for lock and finishes
    XCTAssertEqual(dependentTask.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is true");
    [willFinishLock unlock];
}


- (void)testStartMultipleDependents
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self taskWithLock:willFinishLock];
    TSKTestTask *dependentTask1 = [self taskWithLock:willFinishLock];
    TSKTestTask *dependentTask2 = [self taskWithLock:willFinishLock];

    [graph addTask:task prerequisites:nil];
    [graph addTask:dependentTask1 prerequisites:task, nil];
    [graph addTask:dependentTask2 prerequisites:task, nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask1.state, TSKTaskStatePending, @"dependent state is not pending");
    XCTAssertEqual(dependentTask2.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:kTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task1 starts and task2 finishes
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask1.state, TSKTaskStatePending, @"dependent state is not pending");
    XCTAssertEqual(dependentTask2.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:kTaskDidFinishNotification object:task handler:nil];
    [self expectationForNotification:kTaskDidStartNotification object:dependentTask1 handler:nil];
    [self expectationForNotification:kTaskDidStartNotification object:dependentTask2 handler:nil];
    [willFinishLock unlock];
    // task is waiting for lock and finishes, then dependents begin executing
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask1.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask2.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is not true");

    [self expectationForNotification:kTaskDidFinishNotification object:dependentTask1 handler:nil];
    [self expectationForNotification:kTaskDidFinishNotification object:dependentTask2 handler:nil];
    [willFinishLock unlock];
    // dependentTasks are waiting for lock and finish
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(dependentTask1.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertEqual(dependentTask2.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is true");
}


- (void)testRetry
{
    NSLock *willFailLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self taskWithLock:willFailLock failsWithError:nil];
    [graph addTask:task prerequisites:nil];

    // Put task in typical state for retry
    [self expectationForNotification:kTaskDidFailNotification object:task handler:nil];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateFailed, @"state is not failed");
    XCTAssertTrue(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is not true");
    XCTAssertTrue(graph.hasFailedTasks, @"graph.hasFailedTasks is not true");

    // Test that graph sends retry to its task
    [self expectationForNotification:kTaskDidRetryNotification object:task handler:nil];
    [willFailLock lock];
    [graph retry];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssert((task.state == TSKTaskStateExecuting || task.state == TSKTaskStateReady), @"state is not ready or executing");
    XCTAssertTrue(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is not true");
    XCTAssertFalse(graph.hasFailedTasks, @"graph.hasFailedTasks did not update with retry");
    [willFailLock unlock];
}


- (void)testCancel
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTestTask *task = [self taskWithLock:willFinishLock];
    [graph addTask:task prerequisites:nil];

    // Put task mid-execution
    [self expectationForNotification:kTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");

    // Test that graph sends cancel to its task
    [self expectationForNotification:kTaskDidCancelNotification object:task handler:nil];
    [graph cancel];
    [willFinishLock unlock];
    // Task is waiting for lock and finishes executing. However, it should have received -cancel and thus not honor finish
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"cancel not sent to task");
    XCTAssertTrue(graph.hasUnfinishedTasks, @"graph.hasUnfinishedTasks is not true");
    XCTAssertFalse(graph.hasFailedTasks, @"graph.hasFailedTasks is not false");
}


#pragma mark Helper methods

- (TSKTestTask *)task
{
    return [[TSKTestTask alloc] init];
}

- (TSKTestTask *)taskWithLock:(NSLock *)lock
{
    return [self taskWithLock:lock finishWithResult:nil];
}


- (TSKTestTask *)taskWithLock:(NSLock *)lock finishWithResult:(id)result
{
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [lock lock];
        [task finishWithResult:result];
        [lock unlock];
    }];

    return task;
}


- (TSKTestTask *)taskWithLock:(NSLock *)lock failsWithError:(NSError *)error
{
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [lock lock];
        [task failWithError:error];
        [lock unlock];
    }];
    
    return task;
}

@end
