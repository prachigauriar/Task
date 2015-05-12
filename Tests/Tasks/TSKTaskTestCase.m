//
//  TSKTaskTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/3/14.
//  Copyright (c) 2015 Ticketmaster. All rights reserved.
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

#import <URLMock/UMKMessageCountingProxy.h>


#pragma mark - Test Delegate

@interface TSKTestTaskDelegate : NSObject <TSKTaskDelegate>

@property (nonatomic, strong) TSKTask *task;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

@end


@implementation TSKTestTaskDelegate

- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.task = task;
    self.error = error;
}


- (void)task:(TSKTask *)task didFinishWithResult:(id)result
{
    self.task = task;
    self.result = result;
}


- (void)taskDidCancel:(TSKTask *)task
{
    self.task = task;
}

@end


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

- (void)testTaskDelegateFinish;
- (void)testTaskDelegateFail;
- (void)testTaskDelegateCancel;

- (void)testPrerequisiteResultMethods;

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

    XCTAssertEqual(workflow, task.workflow, @"workflow is set incorrectly");
    XCTAssertEqualObjects(task.prerequisiteTasks, [NSSet set], @"prereqs not empty");
    XCTAssertEqualObjects(task.dependentTasks, [NSSet set], @"dependents not empty");

    TSKTask *dependent = [[TSKTask alloc] init];
    [workflow addTask:dependent prerequisites:task, nil];

    XCTAssertEqualObjects(task.dependentTasks, [NSSet setWithObject:dependent], @"dependents is set incorrectly");
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
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance, @"finish date not set correctly");
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
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance, @"finish date not set correctly");
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

    // Don’t expect that the tasks will retry, because they’re already pending or ready
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

    // Invoke cancel only after main has been entered
    [self expectationForNotification:TSKTestTaskDidCancelNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidCancelNotification task:task];

    [task cancel];

    [self waitForExpectationsWithTimeout:1 handler:nil];
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

    [self expectationForNotification:TSKTestTaskDidCancelNotification object:task handler:nil];
    [self expectationForNotification:TSKTaskDidCancelNotification task:task];

    [task cancel];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

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
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance, @"finish date not set correctly");
    XCTAssertNotNil(task.result, @"result not set");

    NSString *newResult = UMKRandomAlphanumericString();
    NSParameterAssert(newResult != task.result);

    // Test that reset occurs and properties are reset
    [self expectationForNotification:TSKTaskDidResetNotification task:task];
    [self expectationForNotification:TSKTestTaskDidResetNotification object:task handler:nil];

    [task reset];

    // Wait for task to reset before testing that results were reset
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertNil(task.finishDate, @"finish date was not reset");
    XCTAssertNil(task.result, @"result was not reset to nil");

    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];

    [task start];

    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");

    // Test task finishes correctly with new date and result
    [task finishWithResult:newResult];
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance, @"finish date not set correctly");
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


#pragma mark -

- (TSKTask *)taskExecutingWithDelegate:(id)delegate
{
    XCTestExpectation *didStartExpectation = [self expectationWithDescription:@"did start"];
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [didStartExpectation fulfill];
    }];
    task.delegate = delegate;

    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    [workflow addTask:task prerequisites:nil];
    [task start];

    [self waitForExpectationsWithTimeout:1 handler:nil];

    return task;
}


- (void)testTaskDelegateFinish
{
    NSString *result = UMKRandomUnicodeString();

    // Test delegate only implementing finish
    id delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestTaskDelegate alloc] init]];
    TSKTask *task = [self taskExecutingWithDelegate:delegate];

    [task finishWithResult:result];

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(task:didFinishWithResult:)],
                   @"delegate received task:didFinishWithResult: incorrect number of times");
    XCTAssertEqualObjects([delegate task], task, @"delegate message received with incorrect task parameter");
    XCTAssertEqualObjects([delegate result], result, @"delegate message received with incorrect result parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(task:didFailWithError:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(taskDidCancel:)], @"delegate received unexpected selector");

    // Object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    task = [self taskExecutingWithDelegate:delegate];

    XCTAssertNoThrow([task finishWithResult:result], @"delegate that does not implement messages is sent unexpected selector");
}


- (void)testTaskDelegateFail
{
    NSError *error = UMKRandomError();

    // Test delegate only implementing finish
    id delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestTaskDelegate alloc] init]];
    TSKTask *task = [self taskExecutingWithDelegate:delegate];

    [task failWithError:error];

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(task:didFailWithError:)],
                   @"delegate received task:didFailWithError: incorrect number of times");
    XCTAssertEqualObjects([delegate task], task, @"delegate message received with incorrect task parameter");
    XCTAssertEqualObjects([delegate error], error, @"delegate message received with incorrect error parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(task:didFinishWithResult:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(taskDidCancel:)], @"delegate received unexpected selector");

    // Object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    task = [self taskExecutingWithDelegate:delegate];

    XCTAssertNoThrow([task failWithError:error], @"delegate that does not implement messages is sent unexpected selector");
}


- (void)testTaskDelegateCancel
{
    // Test delegate only implementing finish
    id delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestTaskDelegate alloc] init]];
    TSKTask *task = [self taskExecutingWithDelegate:delegate];

    [task cancel];

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(taskDidCancel:)],
                   @"delegate received taskDidCancel: incorrect number of times");
    XCTAssertEqualObjects([delegate task], task, @"delegate message received with incorrect task parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(task:didFinishWithResult:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(task:didFailWithError:)], @"delegate received unexpected selector");

    // Object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    task = [self taskExecutingWithDelegate:delegate];

    XCTAssertNoThrow([task cancel], @"delegate that does not implement messages is sent unexpected selector");
}


- (void)testPrerequisiteResultMethods
{
    NSUInteger elementCount = random() % 5 + 5;
    NSArray *results = UMKGeneratedArrayWithElementCount(elementCount, ^id(NSUInteger index) {
        return UMKRandomUnicodeStringWithLength(64);
    });

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    NSArray *prerequisiteTasks = UMKGeneratedArrayWithElementCount(elementCount, ^id(NSUInteger index) {
        TSKTask *task = [self finishingTaskWithLock:nil result:results[index]];
        [workflow addTask:task prerequisites:nil];
        return task;
    });

    // Task 1 is for testing non-nil results. Task 2 is for testing nil ones.
    TSKTask *task1 = [self finishingTaskWithLock:nil];
    TSKTask *task2 = [self finishingTaskWithLock:nil];
    [workflow addTask:task1 prerequisiteTasks:workflow.allTasks];
    [workflow addTask:task2 prerequisites:task1, nil];

    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Task 1 tests
    XCTAssertTrue([results containsObject:[task1 anyPrerequisiteResult]], @"anyPrerequisiteResult returns non-result object");

    NSCountedSet *expectedResultsCountedSet = [[NSCountedSet alloc] initWithArray:results];
    NSCountedSet *actualResultsCountedSet = [[NSCountedSet alloc] initWithArray:[task1 allPrerequisiteResults]];
    XCTAssertEqualObjects(expectedResultsCountedSet, actualResultsCountedSet, @"allPrerequisiteResults returns incorrect results");

    NSMapTable *expectedResultsMapTable = [NSMapTable strongToStrongObjectsMapTable];
    for (NSUInteger i = 0; i < elementCount; ++i) {
        [expectedResultsMapTable setObject:results[i] forKey:prerequisiteTasks[i]];
    }

    XCTAssertEqualObjects([task1 prerequisiteResultsByTask], expectedResultsMapTable, @"prerequisiteResultsByTask returns incorrect results");

    // Task 2 tests
    XCTAssertNil([task2 anyPrerequisiteResult], @"anyPrerequisiteResult returns non-nil object");
    XCTAssertEqualObjects([task2 allPrerequisiteResults], @[ [NSNull null] ], @"allPrerequisiteResults returns incorrect results");

    [expectedResultsMapTable removeAllObjects];
    [expectedResultsMapTable setObject:[NSNull null] forKey:task1];
    XCTAssertEqualObjects([task2 prerequisiteResultsByTask], expectedResultsMapTable, @"prerequisiteResultsByTask returns incorrect results");
}

@end
