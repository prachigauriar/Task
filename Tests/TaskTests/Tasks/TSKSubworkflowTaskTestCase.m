//
//  TSKSubworkflowTaskTestCase.m
//  Task
//
//  Created by Prachi Gauriar on 12/27/2014.
//  Copyright (c) 2015 Prachi Gauriar. All rights reserved.
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


@interface TSKSubworkflowTaskTestCase : TSKRandomizedTestCase

- (void)testInit;

- (void)testMain;
- (void)testCancel;
- (void)testReset;
- (void)testRetry;

- (void)testSubworkflowFinishesBefore;
- (void)testSubworkflowFinishesAfter;
- (void)testSubworkflowFailsBefore;
- (void)testSubworkflowFailsAfter;
- (void)testSubworkflowCancelsBefore;
- (void)testSubworkflowCancelsAndFailsBefore;
- (void)testSubworkflowCancelsAfter;

@end


@implementation TSKSubworkflowTaskTestCase

- (void)testInit
{
    id nilObject = nil;
    XCTAssertThrows(([[TSKSubworkflowTask alloc] initWithSubworkflow:nilObject]), @"nil subworkflow does not throw exception");
    XCTAssertThrows(([[TSKSubworkflowTask alloc] initWithName:UMKRandomAlphanumericString() subworkflow:nilObject]),
                    @"nil subworkflow does not throw exception");

    TSKWorkflow *subworkflow = [[TSKWorkflow alloc] init];

    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.subworkflow, subworkflow, @"subworkflow is set incorrectly");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKSubworkflowTask alloc] initWithName:name subworkflow:subworkflow];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.subworkflow, subworkflow, @"subworkflow is set incorrectly");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
}


- (void)testMain
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    // Make sure subworkflow is started
    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:subworkflow block:nil];

    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}


- (void)testCancel
{
    NSLock *finishLock = [[NSLock alloc] init];
    [finishLock lock];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKTestTask *subworkflowFinishingTask = [self finishingTaskWithLock:finishLock];
    [subworkflow addTask:subworkflowFinishingTask prerequisites:nil];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    // Make sure subworkflow is sent the -cancel message and that the subworkflow task is also cancelled.
    [self expectationForNotification:TSKWorkflowWillCancelNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKTaskDidCancelNotification task:task];

    [task cancel];
    [finishLock unlock];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isCancelled, @"task is not cancelled");
    XCTAssertTrue(subworkflowFinishingTask.isCancelled, @"subworkflow task is not cancelled");
}


- (void)testReset
{
    NSLock *finishLock = [[NSLock alloc] init];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKTestTask *subworkflowFinishingTask = [self finishingTaskWithLock:finishLock];
    [subworkflow addTask:subworkflowFinishingTask prerequisites:nil];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidFinishNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Make sure subworkflow is sent the -reset message and that the subworkflow task is also reset.
    [self expectationForNotification:TSKWorkflowWillResetNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKTaskDidResetNotification task:task];

    [task reset];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isReady, @"task is not ready");
    XCTAssertTrue(subworkflowFinishingTask.isReady, @"subworkflow task is not ready");
}


- (void)testRetry
{
    NSLock *failLock = [[NSLock alloc] init];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKTestTask *subworkflowFailingTask = [self failingTaskWithLock:failLock];
    [subworkflow addTask:subworkflowFailingTask prerequisites:nil];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidFailNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Make sure subworkflow is sent the -retry message and that the subworkflow task is also retried.
    [self expectationForNotification:TSKWorkflowWillRetryNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKTaskDidRetryNotification task:task];
    [self expectationForNotification:TSKTaskDidFailNotification task:task];

    [task retry];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFailed, @"task is not failed");
    XCTAssertTrue(subworkflowFailingTask.isFailed, @"subworkflow task is not failed");
}


- (void)testSubworkflowFinishesBefore
{
    // Run the empty subworkflow before starting the subworkflow task
    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:subworkflow block:nil];
    [subworkflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    // Start the subworkflow task
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(task.isFinished, @"task is not finished");
    XCTAssertEqualObjects(task.result, subworkflow, @"result is set incorrectly");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);

    // Reinitialize the workflow and task so we can test with a non-empty subworkflow
    workflow = [self workflowForNotificationTesting];
    task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    // Add a task to the subworkflow and run it
    TSKTask *subworkflowFinishingTask = [self finishingTaskWithLock:nil];
    [subworkflow addTask:subworkflowFinishingTask prerequisites:nil];
    [self expectationForNotification:TSKTaskDidFinishNotification task:subworkflowFinishingTask];
    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:subworkflow block:nil];
    [subworkflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    [self expectationForNotification:TSKTaskDidFinishNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(task.isFinished, @"task is not finished");
    XCTAssertEqualObjects(task.result, subworkflow, @"result is set incorrectly");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);
}


- (void)testSubworkflowFinishesAfter
{
    // Empty subworkflow
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFinished, @"task is not finished");
    XCTAssertEqualObjects(task.result, subworkflow, @"result is set incorrectly");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);

    // Non-empty subworkflow
    workflow = [self workflowForNotificationTesting];
    task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    // Add a task to the subworkflow
    NSLock *finishingLock = [[NSLock alloc] init];
    [finishingLock lock];
    TSKTask *subworkflowFinishingTask = [self finishingTaskWithLock:finishingLock];
    [subworkflow addTask:subworkflowFinishingTask prerequisites:nil];

    // Start the subworkflow finishing task, but don’t allow it to finish just yet
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidStartNotification task:subworkflowFinishingTask];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Allow the subworkflow finishing task to finish. This should cause the subworkflow task to finish
    [self expectationForNotification:TSKTaskDidFinishNotification task:subworkflowFinishingTask];
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];
    [finishingLock unlock];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFinished, @"task is not finished");
    XCTAssertEqualObjects(task.result, subworkflow, @"result is set incorrectly");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);
}


- (void)testSubworkflowFailsBefore
{
    TSKTask *task1 = [self failingTaskWithLock:nil error:UMKRandomError()];
    TSKTask *task2 = [self failingTaskWithLock:nil error:UMKRandomError()];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    [subworkflow addTask:task1 prerequisites:nil];
    [subworkflow addTask:task2 prerequisites:nil];

    // Run the subworkflow and let it fail
    [self expectationForNotification:TSKWorkflowTaskDidFailNotification workflow:subworkflow block:nil];
    [subworkflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Run the subworkflow task, expecting it to fail immediately
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidFailNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // The error should be the error of the failed task with the earliest finish date
    TSKTask *failedTask = [task1.finishDate compare:task2.finishDate] < NSOrderedSame ? task1 : task2;

    XCTAssertTrue(task.isFailed, @"task is not failed");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);
    XCTAssertEqualObjects(task.error, failedTask.error, @"error is set incorrectly");
}


- (void)testSubworkflowFailsAfter
{
    // Create a subworkflow with a failing task in it
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    NSError *failingTaskError = UMKRandomError();
    NSLock *failingLock = [[NSLock alloc] init];
    [failingLock lock];
    TSKTask *subworkflowFailingTask = [self failingTaskWithLock:failingLock error:failingTaskError];
    [subworkflow addTask:subworkflowFailingTask prerequisites:nil];

    // Start the subworkflow task, and thus the subworkflow failing task, but don’t allow it to fail just yet
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidStartNotification task:subworkflowFailingTask];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Allow the subworkflow failing task to fail. This should cause the subworkflow task to fail
    [self expectationForNotification:TSKTaskDidFailNotification task:subworkflowFailingTask];
    [self expectationForNotification:TSKTaskDidFailNotification task:task];
    [failingLock unlock];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFailed, @"task is not failed");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);
    XCTAssertEqualObjects(task.error, failingTaskError, @"error is set incorrectly");
}


- (void)testSubworkflowCancelsBefore
{
    TSKTask *cancellingTask = [self cancellingTaskWithLock:nil];
    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    [subworkflow addTask:cancellingTask prerequisites:nil];

    // Run the subworkflow and let it cancel
    [self expectationForNotification:TSKWorkflowTaskDidCancelNotification workflow:subworkflow block:nil];
    [subworkflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Run the subworkflow task, expecting it to cancel immediately
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidCancelNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isCancelled, @"task is not cancelled");
}


- (void)testSubworkflowCancelsAndFailsBefore
{
    TSKTask *cancellingTask = [self cancellingTaskWithLock:nil];
    NSError *error = UMKRandomError();
    TSKTask *failingTask = [self failingTaskWithLock:nil error:error];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    [subworkflow addTask:cancellingTask prerequisites:nil];
    [subworkflow addTask:failingTask prerequisites:nil];

    // Run the subworkflow and let it cancel/fail
    [self expectationForNotification:TSKWorkflowTaskDidFailNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKWorkflowTaskDidCancelNotification workflow:subworkflow block:nil];
    [subworkflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Run the subworkflow task, expecting it to fail, not cancel, immediately
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidFailNotification task:task];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFailed, @"task is not cancelled");
    XCTAssertEqualWithAccuracy([task.finishDate timeIntervalSinceNow], 0, kTSKRandomizedTestCaseDateTolerance);
    XCTAssertEqualObjects(task.error, error, @"error is set incorrectly");
}


- (void)testSubworkflowCancelsAfter
{
    // Create a subworkflow with a cancelling task in it
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    NSLock *cancelLock = [[NSLock alloc] init];
    [cancelLock lock];
    TSKTask *subworkflowCancellingTask = [self cancellingTaskWithLock:cancelLock];
    [subworkflow addTask:subworkflowCancellingTask prerequisites:nil];

    // Start the subworkflow task, and thus the subworkflow cancelling task, but don’t allow it to cancel just yet
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidStartNotification task:subworkflowCancellingTask];
    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Allow the subworkflow cancelling task to cancel. This should cause the subworkflow task to cancel
    [self expectationForNotification:TSKTaskDidCancelNotification task:subworkflowCancellingTask];
    [self expectationForNotification:TSKTaskDidCancelNotification task:task];
    [cancelLock unlock];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isCancelled, @"task is not cancelled");
}

@end
