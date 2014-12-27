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


#pragma mark Constants

static const NSTimeInterval kFinishDateTolerance = 0.1;


#pragma mark - 

@interface TSKTaskTestCase : TSKRandomizedTestCase

- (void)testInit;
- (void)testWorkflow;
- (void)testStart;
- (void)testOperationQueue;
- (void)testFinish;
- (void)testFail;
- (void)testRetry;
- (void)testCancelAndFinish;
- (void)testCancelAndFail;
- (void)testReset;

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
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state not set to default");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKTask alloc] initWithName:name];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, name, @"name not set to default");
    XCTAssertNotEqualObjects(task.name, notName, @"name not set correctly");
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state not set to default");

    task = [[TSKTask alloc] initWithName:nil];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
}


- (void)testWorkflow
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTask *task = [[TSKTask alloc] init];
    [workflow addTask:task prerequisites:nil];

    XCTAssertEqual(workflow, task.workflow, @"workflow not set properly");
    XCTAssertEqualObjects(task.prerequisiteTasks, [NSSet set], @"prereqs not empty");
    XCTAssertEqualObjects(task.dependentTasks, [NSSet set], @"dependents not empty");

    TSKTask *dependent = [[TSKTask alloc] init];
    [workflow addTask:dependent prerequisites:task, nil];

    XCTAssertEqualObjects(task.dependentTasks, [NSSet setWithObject:dependent], @"dependents not set properly");
    XCTAssertEqualObjects(dependent.prerequisiteTasks, [NSSet setWithObject:task], @"prereqs not set property");

    XCTAssertEqual(dependent.state, TSKTaskStatePending, @"dependent state not set to pending");
}


- (void)testStart
{
    TSKTestTask *task = [[TSKTestTask alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");

    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];

    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
}


- (void)testOperationQueue
{
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithOperationQueue:operationQueue];
    XCTestExpectation *testDidRunExpectation = [self expectationWithDescription:@"test for operation queue did run"];

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        XCTAssertEqualObjects(operationQueue, [NSOperationQueue currentQueue], @"task not executing on correct queue");
        [testDidRunExpectation fulfill];
    }];

    [workflow addTask:task prerequisites:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)testFinish
{
    NSString *resultString = UMKRandomUnicodeString();
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [task finishWithResult:resultString];
    }];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];

    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(task.result, resultString, @"result not set correctly");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kFinishDateTolerance, @"finish date not set correctly");
}


- (void)testFail
{
    NSError *error = UMKRandomError();
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [task failWithError:error];
    }];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidFailNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidFailNotification task:task];

    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual(task.state, TSKTaskStateFailed, @"state  is not failed");
    XCTAssertEqualObjects(task.error, error, @"error not returned correcctly");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kFinishDateTolerance, @"finish date not set correctly");
}


- (void)testRetry
{
    TSKTestTask *task = [[TSKTestTask alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];

    // Put task in a typical state for retry
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [task failWithError:nil];

    [self expectationForNotification:TSKTaskDidRetryNotification task:task];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTestTaskDidRetryNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];

    [task retry];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    // Test that retry triggers state change to executing and that finishing is then possible
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    [task finishWithResult:nil];
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");

    workflow = [self workflowForNotificationTesting];

    // Test that when task receives retry, it sends to dependents
    task = [[TSKTestTask alloc] init];
    TSKTestTask *dependent1 = [[TSKTestTask alloc] init];
    TSKTestTask *dependent2 = [[TSKTestTask alloc] init];

    [workflow addTask:task prerequisites:nil];
    [workflow addTask:dependent1 prerequisites:task, nil];
    [workflow addTask:dependent2 prerequisites:task, nil];

    // Don’t expect that the dependent tasks will get a retry message, because they’re already in the
    // pending state and thus won’t re-transition to that state
    [self expectationForNotification:TSKTaskDidRetryNotification task:task];

    [self expectationForNotification:TSKTestTaskDidRetryNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidRetryNotification object:dependent1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidRetryNotification object:dependent2 handler:nil];

    [task retry];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)testCancelAndFinish
{
    NSLock *didCancelLock = [[NSLock alloc] init];
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        // Pause for lock to ensure this executes after -cancel
        [didCancelLock lock];
        [task finishWithResult:UMKRandomAlphanumericString()];
        [didCancelLock unlock];
    }];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];

    // Lock to ensure state transitions to cancelled before -finishWithResult: is called
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [didCancelLock lock];
    [task start];

    // Confirms that task is mid-execution when -cancel is called
    [self waitForExpectationsWithTimeout:1 handler:nil];

    // Call cancel only after main has been entered
    [task cancel];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"state is not cancelled");
    [didCancelLock unlock];

    // Block is waiting for lock and executes before this continues
    // Test that -finishWithResult: is called on task but is not honored in cancelled state
    [didCancelLock lock];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"finish is honored on cancelled task");
    XCTAssertNil(task.result, @"finish is honored on cancelled task");
    XCTAssertNil(task.finishDate, @"finish is honored on cancelled task");

    [didCancelLock unlock];

    workflow = [self workflowForNotificationTesting];

    // Test that when task receives cancel, it sends to dependents
    task = [[TSKTestTask alloc] init];
    TSKTestTask *dependent1 = [[TSKTestTask alloc] init];
    TSKTestTask *dependent2 = [[TSKTestTask alloc] init];

    [workflow addTask:task prerequisites:nil];
    [workflow addTask:dependent1 prerequisites:task, nil];
    [workflow addTask:dependent2 prerequisites:task, nil];

    [self expectationForNotification:TSKTaskDidCancelNotification task:task];
    [self expectationForNotification:TSKTaskDidCancelNotification task:dependent1];
    [self expectationForNotification:TSKTaskDidCancelNotification task:dependent2];

    [self expectationForNotification:TSKTestTaskDidCancelNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidCancelNotification object:dependent1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidCancelNotification object:dependent2 handler:nil];

    [task cancel];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)testCancelAndFail
{
    NSLock *didCancelLock = [[NSLock alloc] init];
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        // Pause to ensure state is cancelled before failWithError: is called
        [didCancelLock lock];
        [task failWithError:UMKRandomError()];
        [didCancelLock unlock];
    }];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [didCancelLock lock];
    [task start];

    // Ensure task is executing before cancel is called
    [self waitForExpectationsWithTimeout:1 handler:nil];

    [task cancel];
    [didCancelLock unlock];

    // Block is waiting for lock and executes before this continues
    // Test that -failWithError: is called on task but is not honored in cancelled state
    [didCancelLock lock];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"fail is honored on cancelled task");
    XCTAssertNil(task.error, @"fail is honored on cancelled task");
    XCTAssertNil(task.finishDate, @"fail is honored on cancelled task");

    [didCancelLock unlock];
}


- (void)testReset
{
    TSKTestTask *task = [[TSKTestTask alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [task finishWithResult:UMKRandomUnicodeString()];

    // Confirm task is finished and relevant properties have been set before resetting
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kFinishDateTolerance, @"finish date not set correctly");
    XCTAssertNotNil(task.result, @"result not set");

    NSString *newResult = UMKRandomAlphanumericString();
    NSParameterAssert(newResult != task.result);

    // Test that reset occurs and properties are reset
    [self expectationForNotification:TSKTaskDidResetNotification task:task];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTestTaskDidResetNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];

    [task reset];

    // Wait for task to reset and start executing before testing that results were reset
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertNil(task.finishDate, @"finish date was not reset");
    XCTAssertNil(task.result, @"result was not reset to nil");

    // Test task finishes correctly with new date and result
    [task finishWithResult:newResult];
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kFinishDateTolerance, @"finish date not set correctly");
    XCTAssertEqual(task.result, newResult, @"result not set correctly");

    // Test that when task receives reset, it sends to dependents
    task = [[TSKTestTask alloc] init];
    TSKTestTask *dependent1 = [[TSKTestTask alloc] init];
    TSKTestTask *dependent2 = [[TSKTestTask alloc] init];
    workflow = [self workflowForNotificationTesting];
    [workflow addTask:task prerequisites:nil];
    [workflow addTask:dependent1 prerequisites:task, nil];
    [workflow addTask:dependent2 prerequisites:task, nil];

    // Don’t expect the tasks to post did reset notifications, because they’re not in a resettable state
    [self expectationForNotification:TSKTestTaskDidResetNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidResetNotification object:dependent1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidResetNotification object:dependent2 handler:nil];


    [task reset];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end


// State transitions:
//     Pending -> Ready: All of task’s prerequisite tasks are finished (-startIfReady)
//     Pending -> Cancelled: Task is cancelled (-cancel)
//
//     Ready -> Pending: Task is added to a workflow with at least one prerequisite task (-didAddPrerequisiteTask)
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

