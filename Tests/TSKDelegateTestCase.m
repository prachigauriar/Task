//
//  TSKDelegateTestCase.m
//  Task
//
//  Created by Jill Cohen on 12/3/14.
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


#pragma mark Helper Classes for Task Delegates

@interface TSKTaskDelegateFinish : NSObject <TSKTaskDelegate>

@property (nonatomic, assign) NSUInteger didReceiveFinishCount;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) TSKTask *task;

@end


@implementation TSKTaskDelegateFinish

- (void)task:(TSKTask *)task didFinishWithResult:(id)result
{
    self.didReceiveFinishCount++;
    self.result = result;
    self.task = task;
}

@end


@interface TSKTaskDelegateFail : NSObject <TSKTaskDelegate>

@property (nonatomic, assign) NSUInteger didReceiveFailCount;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) TSKTask *task;

@end


@implementation TSKTaskDelegateFail

- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFailCount++;
    self.error = error;
    self.task = task;
}

@end


@interface TSKTaskDelegateFinishAndFail : TSKTaskDelegateFinish

@property (nonatomic, assign) NSUInteger didReceiveFailCount;
@property (nonatomic, strong) NSError *error;

@end


@implementation TSKTaskDelegateFinishAndFail

- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFailCount++;
    self.error = error;
    self.task = task;
}

@end


#pragma mark - Helper Classes for Workflow Delegates

@interface TSKWorkflowDelegateFinish : NSObject <TSKWorkflowDelegate>

@property (nonatomic, assign) NSUInteger didReceiveFinishCount;
@property (nonatomic, strong) TSKWorkflow *workflow;

@end


@implementation TSKWorkflowDelegateFinish

- (void)workflowDidFinish:(TSKWorkflow *)workflow
{
    self.didReceiveFinishCount++;
    self.workflow = workflow;
}

@end


@interface TSKWorkflowDelegateFail : NSObject <TSKWorkflowDelegate>

@property (nonatomic, assign) NSUInteger didReceiveFailCount;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) TSKWorkflow *workflow;
@property (nonatomic, strong) TSKTask *task;

@end


@implementation TSKWorkflowDelegateFail

- (void)workflow:(TSKWorkflow *)workflow task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFailCount++;
    self.error = error;
    self.workflow = workflow;
    self.task = task;
}

@end


@interface TSKWorkflowDelegateFinishAndFail : TSKWorkflowDelegateFinish

@property (nonatomic, assign) NSUInteger didReceiveFailCount;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) TSKTask *task;

@end


@implementation TSKWorkflowDelegateFinishAndFail

- (void)workflow:(TSKWorkflow *)workflow task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFailCount++;
    self.error = error;
    self.workflow = workflow;
    self.task = task;
}

@end


#pragma mark - Tests for Delegate Methods

@interface TSKDelegateTestCase : TSKRandomizedTestCase

- (void)testTaskDelegateFinish;
- (void)testTaskDelegateFail;
- (void)testWorkflowDelegateFinish;
- (void)testWorkflowDelegateFail;
- (void)testWorkflowDelegateNoTasks;

@end


@implementation TSKDelegateTestCase

- (void)testTaskDelegateFinish
{
    NSString *resultString = UMKRandomUnicodeString();

    // Test delegate only implementing finish
    TSKTaskDelegateFinish *finishDelegate = [[TSKTaskDelegateFinish alloc] init];
    TSKTask *task = [self taskExecutingWithDelegate:finishDelegate];

    [task finishWithResult:resultString];

    XCTAssertEqual(finishDelegate.didReceiveFinishCount, 1, @"delegate method not sent exactly once to delegate implementing it");
    XCTAssertEqual(resultString, finishDelegate.result, @"correct result not passed");
    XCTAssertEqual(finishDelegate.task, task, @"correct task not passed");

    // Test delegate only implementing fail
    TSKTaskDelegateFail *failDelegate = [[TSKTaskDelegateFail alloc] init];
    task = [self taskExecutingWithDelegate:failDelegate];

    XCTAssertNoThrow([task finishWithResult:resultString], @"messages the delegate a method it doesn't implement");
    XCTAssertEqual(failDelegate.didReceiveFailCount, 0, @"wrong delegate method sent");

    // Test delegate implementing both optional methods
    TSKTaskDelegateFinishAndFail *finishAndFailDelegate = [[TSKTaskDelegateFinishAndFail alloc] init];
    task = [self taskExecutingWithDelegate:finishAndFailDelegate];

    [task finishWithResult:resultString];

    XCTAssertEqual(finishAndFailDelegate.didReceiveFinishCount, 1, @"delegate method not sent exactly once to delegate implementing it");
    XCTAssertEqual(resultString, finishAndFailDelegate.result, @"correct result not passed");
    XCTAssertEqual(finishAndFailDelegate.task, task, @"correct task not passed");
    XCTAssertEqual(finishAndFailDelegate.didReceiveFailCount, 0, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
}


- (void)testTaskDelegateFail
{
    NSError *error = UMKRandomError();

    // Test delegate only implementing fail
    TSKTaskDelegateFail *failDelegate = [[TSKTaskDelegateFail alloc] init];
    TSKTask *task = [self taskExecutingWithDelegate:failDelegate];

    [task failWithError:error];

    XCTAssertEqual(failDelegate.didReceiveFailCount, 1, @"delegate method not sent to delegate implementing it");
    XCTAssertEqualObjects(error, failDelegate.error, @"correct error not passed");
    XCTAssertEqual(failDelegate.task, task, @"correct task not passed");

    // Test with nil error
    failDelegate = [[TSKTaskDelegateFail alloc] init];
    task = [self taskExecutingWithDelegate:failDelegate];

    [task failWithError:nil];

    XCTAssertEqual(failDelegate.didReceiveFailCount, 1, @"delegate method not sent to delegate implementing it");
    XCTAssertNil(failDelegate.error, @"error is non-nil");
    XCTAssertEqual(failDelegate.task, task, @"correct task not passed");

    // Test delegate only implementing finish
    TSKTaskDelegateFinish *finishDelegate = [[TSKTaskDelegateFinish alloc] init];
    task = [self taskExecutingWithDelegate:finishDelegate];

    XCTAssertNoThrow([task failWithError:error], @"messages the delegate a method it doesn't implement");
    XCTAssertEqual(finishDelegate.didReceiveFinishCount, 0, @"wrong delegate method sent");

    // Test delegate implementing both optional methods
    TSKTaskDelegateFinishAndFail *finishAndFailDelegate = [[TSKTaskDelegateFinishAndFail alloc] init];
    task = [self taskExecutingWithDelegate:finishAndFailDelegate];

    [task failWithError:error];

    XCTAssertEqual(finishAndFailDelegate.didReceiveFailCount, 1, @"delegate method not sent to delegate implementing it");
    XCTAssertEqualObjects(error, finishAndFailDelegate.error, @"correct error not passed");
    XCTAssertEqual(finishAndFailDelegate.task, task, @"correct task not passed");
    XCTAssertEqual(finishAndFailDelegate.didReceiveFinishCount, 0, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.result, @"wrong delegate method sent");
}


- (void)testWorkflowDelegateFinish
{
    // Test delegate only implementing finish
    TSKWorkflowDelegateFinish *finishDelegate = [[TSKWorkflowDelegateFinish alloc] init];
    TSKWorkflow *workflow = [self finishWorkflowWithDelegate:finishDelegate];

    XCTAssertEqual(finishDelegate.didReceiveFinishCount, 1, @"delegate method not sent exactly once to delegate implementing it");
    XCTAssertEqual(finishDelegate.workflow, workflow, @"correct workflow not sent");

    // Test delegate only implementing fail
    TSKWorkflowDelegateFail *failDelegate = [[TSKWorkflowDelegateFail alloc] init];
    XCTAssertNoThrow([self finishWorkflowWithDelegate:failDelegate], @"messages the delegate a method it doesn't implement");
    XCTAssertEqual(failDelegate.didReceiveFailCount, 0, @"wrong delegate method sent");

    // Test delegate implementing both optional methods
    TSKWorkflowDelegateFinishAndFail *finishAndFailDelegate = [[TSKWorkflowDelegateFinishAndFail alloc] init];
    workflow = [self finishWorkflowWithDelegate:finishAndFailDelegate];
    XCTAssertEqual(finishAndFailDelegate.didReceiveFinishCount, 1, @"delegate method not sent exactly once to delegate implementing it");
    XCTAssertEqual(finishAndFailDelegate.workflow, workflow, @"correct workflow not passed");
    XCTAssertEqual(finishAndFailDelegate.didReceiveFailCount, 0, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.task, @"wrong delegate method sent");
}


- (void)testWorkflowDelegateFail
{
    NSError *error = UMKRandomError();

    // Test delegate only implementing fail
    TSKWorkflowDelegateFail *failDelegate = [[TSKWorkflowDelegateFail alloc] init];
    TSKTask *task = [self failedTaskWithWorkflowDelegate:failDelegate error:error];

    XCTAssertEqual(failDelegate.didReceiveFailCount, 1, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(failDelegate.workflow, task.workflow, @"correct workflow not sent");
    XCTAssertEqual(failDelegate.task, task, @"correct task not sent");
    XCTAssertEqual(failDelegate.error, error, @"correct error not sent");

    // Test with nil error
    failDelegate = [[TSKWorkflowDelegateFail alloc] init];
    task = [self failedTaskWithWorkflowDelegate:failDelegate error:nil];
    XCTAssertEqual(failDelegate.didReceiveFailCount, 1, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(failDelegate.workflow, task.workflow, @"correct workflow not sent");
    XCTAssertEqual(failDelegate.task, task, @"correct task not sent");
    XCTAssertNil(failDelegate.error, @"error is non-nil");

    // Test delegate only implementing finish
    TSKWorkflowDelegateFinish *finishDelegate = [[TSKWorkflowDelegateFinish alloc] init];
    XCTAssertNoThrow([self failedTaskWithWorkflowDelegate:finishDelegate error:error], @"messages the delegate a method it doesn't implement");
    XCTAssertEqual(finishDelegate.didReceiveFinishCount, 0, @"wrong delegate method sent");

    // Test delegate implementing both optional methods
    TSKWorkflowDelegateFinishAndFail *finishAndFailDelegate = [[TSKWorkflowDelegateFinishAndFail alloc] init];
    task = [self failedTaskWithWorkflowDelegate:finishAndFailDelegate error:error];

    XCTAssertEqual(finishAndFailDelegate.didReceiveFailCount, 1, @"delegate method not sent to delegate implementing it");
    XCTAssertEqualObjects(error, finishAndFailDelegate.error, @"correct error not passed");
    XCTAssertEqual(finishAndFailDelegate.workflow, task.workflow, @"correct workflow not passed");
    XCTAssertEqual(finishAndFailDelegate.task, task, @"correct task not passed");
    XCTAssertEqual(finishAndFailDelegate.didReceiveFinishCount, 0, @"wrong delegate method sent");
}


- (void)testWorkflowDelegateNoTasks
{
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    TSKWorkflowDelegateFinishAndFail *finishAndFailDelegate = [[TSKWorkflowDelegateFinishAndFail alloc] init];
    workflow.delegate = finishAndFailDelegate;

    [workflow start];

    XCTAssertEqual(finishAndFailDelegate.didReceiveFinishCount, 1, @"delegate method not sent exactly once to delegate implementing it");
    XCTAssertEqual(finishAndFailDelegate.workflow, workflow, @"correct workflow not passed");
    XCTAssertEqual(finishAndFailDelegate.didReceiveFailCount, 0, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.task, @"wrong delegate method sent");

    workflow = [[TSKWorkflow alloc] init];
    finishAndFailDelegate = [[TSKWorkflowDelegateFinishAndFail alloc] init];
    workflow.delegate = finishAndFailDelegate;

    [workflow retry];

    XCTAssertEqual(finishAndFailDelegate.didReceiveFinishCount, 1, @"delegate method not sent exactly once to delegate implementing it");
    XCTAssertEqual(finishAndFailDelegate.workflow, workflow, @"correct workflow not passed");
    XCTAssertEqual(finishAndFailDelegate.didReceiveFailCount, 0, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.task, @"wrong delegate method sent");
}


#pragma mark - Helper methods

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


- (TSKWorkflow *)finishWorkflowWithDelegate:(id)delegate
{
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    workflow.delegate = delegate;

    XCTestExpectation *didFinishExpectation = [self expectationWithDescription:@"task did finish"];
    TSKTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [task finishWithResult:nil];
        [didFinishExpectation fulfill];
    }];

    [workflow addTask:task prerequisites:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    return workflow;
}


- (TSKTask *)failedTaskWithWorkflowDelegate:(id)delegate error:(NSError *)error
{
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    workflow.delegate = delegate;

    XCTestExpectation *didFinishExpectation = [self expectationWithDescription:@"task did finish"];
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [task failWithError:error];
        [didFinishExpectation fulfill];
    }];

    [workflow addTask:task prerequisites:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    return task;
}

@end
