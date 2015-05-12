//
//  TSKExternalConditionTaskTestCase.m
//  Task
//
//  Created by Prachi Gauriar on 12/27/2014.
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




@interface TSKExternalConditionTaskTestCase : TSKRandomizedTestCase

- (void)testInit;
- (void)testFulfillWithResult;
- (void)testMainFulfilled;
- (void)testMainUnfulfilled;
- (void)testReset;

@end


@implementation TSKExternalConditionTaskTestCase

- (void)testInit
{
    TSKExternalConditionTask *task = [[TSKExternalConditionTask alloc] init];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertFalse(task.isFulfilled, @"task is initially fulfilled");
    XCTAssertNil(task.result, @"result is non-nil");

    NSString *name = UMKRandomAlphanumericString();
    task = [[TSKExternalConditionTask alloc] initWithName:name];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertFalse(task.isFulfilled, @"task is initially fulfilled");
    XCTAssertNil(task.result, @"result is non-nil");
}


- (void)testFulfillWithResult
{
    NSString *result = UMKRandomAlphanumericString();
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKExternalConditionTask *task = [[TSKExternalConditionTask alloc] init];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidFailNotification task:task];

    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFailed, @"task is not failed");

    [self expectationForNotification:TSKTaskDidRetryNotification task:task];
    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];
    [task fulfillWithResult:result];

    // This result should be ignored
    [task fulfillWithResult:UMKRandomAlphanumericString()];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFulfilled, @"task is not fulfilled");
    XCTAssertTrue(task.isFinished, @"task is not finished");
    XCTAssertEqualObjects(task.result, result, @"result is set incorrectly");
    XCTAssertNil(task.error, @"error is non-nil");
}


- (void)testMainFulfilled
{
    NSString *result = UMKRandomAlphanumericString();
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKExternalConditionTask *task = [[TSKExternalConditionTask alloc] init];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];

    [task fulfillWithResult:result];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFulfilled, @"task is not fulfilled");
    XCTAssertEqualObjects(task.result, result, @"result is set incorrectly");
    XCTAssertNil(task.error, @"error is non-nil");
}


- (void)testMainUnfulfilled
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKExternalConditionTask *task = [[TSKExternalConditionTask alloc] init];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidFailNotification task:task];

    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertFalse(task.isFulfilled, @"task is fulfilled");
    XCTAssertNotNil(task.error, @"error is nil");
    XCTAssertEqualObjects(task.error.domain, TSKTaskErrorDomain, @"error domain is set incorrectly");
    XCTAssertEqual(task.error.code, TSKErrorCodeExternalConditionNotFulfilled, @"error code is set incorrectly");
}


- (void)testReset
{
    NSString *result = UMKRandomAlphanumericString();
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKExternalConditionTask *task = [[TSKExternalConditionTask alloc] init];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidFinishNotification task:task];

    [task fulfillWithResult:result];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isFulfilled, @"task is not fulfilled");
    XCTAssertEqualObjects(task.result, result, @"result is set incorrectly");
    XCTAssertNil(task.error, @"error is non-nil");

    [self expectationForNotification:TSKTaskDidResetNotification task:task];
    [task reset];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertFalse(task.isFulfilled, @"task is fulfilled");

    [self expectationForNotification:TSKTaskDidStartNotification task:task];
    [self expectationForNotification:TSKTaskDidFailNotification task:task];

    [task start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertFalse(task.isFulfilled, @"task is fulfilled");
    XCTAssertNotNil(task.error, @"error is nil");
    XCTAssertEqualObjects(task.error.domain, TSKTaskErrorDomain, @"error domain is set incorrectly");
    XCTAssertEqual(task.error.code, TSKErrorCodeExternalConditionNotFulfilled, @"error code is set incorrectly");
}

@end
