//
//  TSKSubworkflowTaskTestCase.m
//  Task
//
//  Created by Prachi Gauriar on 12/27/2014.
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


@interface TSKSubworkflowTaskTestCase : TSKRandomizedTestCase

- (void)testInit;

- (void)testMain;
- (void)testCancel;
- (void)testReset;
- (void)testRetry;

- (void)testSubworkflowDidFinish;
- (void)testSubworkflowTaskDidCancel;
- (void)testSubworkflowTaskDidCancelAddTask;
- (void)testSubworkflowTaskDidFail;

@end


@implementation TSKSubworkflowTaskTestCase

- (void)testInit
{
    XCTAssertThrows(([[TSKSubworkflowTask alloc] init]), @"nil subworkflow does not throw exception");
    XCTAssertThrows(([[TSKSubworkflowTask alloc] initWithName:UMKRandomAlphanumericString()]), @"nil subworkflow does not throw exception");
    XCTAssertThrows(([[TSKSubworkflowTask alloc] initWithSubworkflow:nil]), @"nil subworkflow does not throw exception");
    XCTAssertThrows(([[TSKSubworkflowTask alloc] initWithName:UMKRandomAlphanumericString() subworkflow:nil]), @"nil subworkflow does not throw exception");

    TSKWorkflow *subworkflow = [[TSKWorkflow alloc] init];

    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.subworkflow, subworkflow, @"subworkflow is set incorrectly");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKSubworkflowTask alloc] initWithName:name subworkflow:subworkflow];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
    XCTAssertNil(task.workflow, @"workflow is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
}


- (void)testMain
{
//    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
//    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
//
//    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:subworkflow block:nil];
//    [task main];
//    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}


- (void)testCancel
{
    NSLock *finishLock = [[NSLock alloc] init];
    [finishLock lock];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKTestTask *subworkflowFinishTask = [self finishingTaskWithLock:finishLock];
    [subworkflow addTask:subworkflowFinishTask prerequisites:nil];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKWorkflowWillCancelNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKTaskDidCancelNotification task:task];

    [task cancel];
    [finishLock unlock];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isCancelled, @"task is not cancelled");
    XCTAssertTrue(subworkflowFinishTask.isCancelled, @"subworkflow task is not cancelled");
}


- (void)testReset
{
    NSLock *finishLock = [[NSLock alloc] init];

    TSKWorkflow *subworkflow = [self workflowForNotificationTesting];
    TSKTestTask *subworkflowFinishTask = [self finishingTaskWithLock:finishLock];
    [subworkflow addTask:subworkflowFinishTask prerequisites:nil];

    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKSubworkflowTask *task = [[TSKSubworkflowTask alloc] initWithSubworkflow:subworkflow];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKWorkflowWillCancelNotification workflow:subworkflow block:nil];
    [self expectationForNotification:TSKTaskDidCancelNotification task:task];

    [task cancel];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(task.isCancelled, @"task is not cancelled");
    XCTAssertTrue(subworkflowFinishTask.isCancelled, @"subworkflow task is not cancelled");
}

@end
