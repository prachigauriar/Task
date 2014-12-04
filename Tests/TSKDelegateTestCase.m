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


# pragma mark - Helper Classes for Task Delegates

@interface TaskDelegateFinish : NSObject <TSKTaskDelegate>

@property (nonatomic, assign) BOOL didReceiveFinish;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) TSKTask *task;

@end

@implementation TaskDelegateFinish

- (void)task:(TSKTask *)task didFinishWithResult:(id)result
{
    self.didReceiveFinish = YES;
    self.result = result;
    self.task = task;
}

@end


@interface TaskDelegateFail : NSObject <TSKTaskDelegate>

@property (nonatomic, assign) BOOL didReceiveFail;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) TSKTask *task;

@end

@implementation TaskDelegateFail

- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFail = YES;
    self.error = error;
    self.task = task;
}

@end


@interface TaskDelegateFinishAndFail : TaskDelegateFinish

@property (nonatomic, assign) BOOL didReceiveFail;
@property (nonatomic, strong) NSError *error;

@end

@implementation TaskDelegateFinishAndFail

- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFail = YES;
    self.error = error;
    self.task = task;
}

@end


# pragma mark - Helper Classes for Graph Delegates

@interface GraphDelegateFinish : NSObject <TSKGraphDelegate>

@property (nonatomic, assign) BOOL didReceiveFinish;
@property (nonatomic, strong) TSKGraph *graph;

@end

@implementation GraphDelegateFinish

- (void)graphDidFinish:(TSKGraph *)graph
{
    self.didReceiveFinish = YES;
    self.graph = graph;
}

@end


@interface GraphDelegateFail : NSObject <TSKGraphDelegate>

@property (nonatomic, assign) BOOL didReceiveFail;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) TSKGraph *graph;
@property (nonatomic, strong) TSKTask *task;

@end

@implementation GraphDelegateFail

- (void)graph:(TSKGraph *)graph task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFail = YES;
    self.error = error;
    self.graph = graph;
    self.task = task;
}

@end


@interface GraphDelegateFinishAndFail : GraphDelegateFinish

@property (nonatomic, assign) BOOL didReceiveFail;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) TSKTask *task;

@end

@implementation GraphDelegateFinishAndFail

- (void)graph:(TSKGraph *)graph task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFail = YES;
    self.error = error;
    self.graph = graph;
    self.task = task;
}

@end


#pragma mark - Tests for Delegate Methods

@interface TSKDelegateTestCase : TSKRandomizedTestCase

@end

@implementation TSKDelegateTestCase

- (void)testTaskDelegateFinish
{
    NSString *resultString = UMKRandomUnicodeString();

    // Test delegate only implementing finish
    TaskDelegateFinish *finishDelegate = [[TaskDelegateFinish alloc] init];
    TSKTask *task = [self taskExecutingWithDelegate:finishDelegate];

    [task finishWithResult:resultString];

    XCTAssertTrue(finishDelegate.didReceiveFinish, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(resultString, finishDelegate.result, @"correct result not passed");
    XCTAssertEqual(finishDelegate.task, task, @"correct task not passed");

    // Test delegate only implementing fail
    TaskDelegateFail *failDelegate = [[TaskDelegateFail alloc] init];
    task = [self taskExecutingWithDelegate:failDelegate];

    XCTAssertNoThrow([task finishWithResult:resultString], @"messages the delegate a method it doesn't implement");

    TaskDelegateFinishAndFail *finishAndFailDelegate = [[TaskDelegateFinishAndFail alloc] init];
    task = [self taskExecutingWithDelegate:finishAndFailDelegate];

    [task finishWithResult:resultString];

    // Test delegate implementing both optional methods
    XCTAssertTrue(finishAndFailDelegate.didReceiveFinish, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(resultString, finishAndFailDelegate.result, @"correct result not passed");
    XCTAssertEqual(finishAndFailDelegate.task, task, @"correct task not passed");
    XCTAssertFalse(finishAndFailDelegate.didReceiveFail, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
}


- (void)testTaskDelegateFail
{
    NSError *error = UMKRandomError();

    // Test delegate only implementing fail
    TaskDelegateFail *failDelegate = [[TaskDelegateFail alloc] init];
    TSKTask *task = [self taskExecutingWithDelegate:failDelegate];

    [task failWithError:error];

    XCTAssertTrue(failDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(error, failDelegate.error, @"correct error not passed");
    XCTAssertEqual(failDelegate.task, task, @"correct task not passed");

    // Test with nil error
    failDelegate = [[TaskDelegateFail alloc] init];
    task = [self taskExecutingWithDelegate:failDelegate];

    [task failWithError:nil];

    XCTAssertTrue(failDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertNil(failDelegate.error, @"error is non-nil");
    XCTAssertEqual(failDelegate.task, task, @"correct task not passed");

    // Test delegate only implementing finish
    TaskDelegateFinish *finishDelegate = [[TaskDelegateFinish alloc] init];
    task = [self taskExecutingWithDelegate:finishDelegate];

    XCTAssertNoThrow([task failWithError:error], @"messages the delegate a method it doesn't implement");

    TaskDelegateFinishAndFail *finishAndFailDelegate = [[TaskDelegateFinishAndFail alloc] init];
    task = [self taskExecutingWithDelegate:finishAndFailDelegate];

    [task failWithError:error];

    // Test delegate implementing both optional methods
    XCTAssertTrue(finishAndFailDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(error, finishAndFailDelegate.error, @"correct error not passed");
    XCTAssertEqual(finishAndFailDelegate.task, task, @"correct task not passed");
    XCTAssertFalse(finishAndFailDelegate.didReceiveFinish, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.result, @"wrong delegate method sent");
}


- (void)testGraphDelegateFinish
{
    // Test delegate only implementing finish
    GraphDelegateFinish *finishDelegate = [[GraphDelegateFinish alloc] init];
    TSKGraph *graph = [self finishGraphWithDelegate:finishDelegate];

    XCTAssertTrue(finishDelegate.didReceiveFinish, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(finishDelegate.graph, graph, @"correct graph not sent");

    // Test delegate only implementing fail
    GraphDelegateFail *failDelegate = [[GraphDelegateFail alloc] init];
    XCTAssertNoThrow([self finishGraphWithDelegate:failDelegate], @"messages the delegate a method it doesn't implement");

    // Test delegate implementing both optional methods
    GraphDelegateFinishAndFail *finishAndFailDelegate = [[GraphDelegateFinishAndFail alloc] init];
    graph = [self finishGraphWithDelegate:finishAndFailDelegate];
    XCTAssertTrue(finishAndFailDelegate.didReceiveFinish, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(finishAndFailDelegate.graph, graph, @"correct graoh not passed");
    XCTAssertFalse(finishAndFailDelegate.didReceiveFail, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.task, @"wrong delegate method sent");
}


- (void)testGraphDelegateFail
{
    TSKTask *task = nil;
    NSError *error = nil;

    // Test delegate only implementing fail
    GraphDelegateFail *failDelegate = [[GraphDelegateFail alloc] init];
    TSKGraph *graph = [self failGraphWithDelegate:failDelegate task:&task error:&error];

    XCTAssertTrue(failDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(failDelegate.graph, graph, @"correct graph not sent");
    XCTAssertEqual(failDelegate.task, task, @"correct task not sent");
    XCTAssertEqual(failDelegate.error, error, @"correct error not sent");

    // Test with nil error
    failDelegate = [[GraphDelegateFail alloc] init];
    graph = [self failGraphWithDelegate:failDelegate task:&task error:nil];
    XCTAssertTrue(failDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(failDelegate.graph, graph, @"correct graph not sent");
    XCTAssertEqual(failDelegate.task, task, @"correct task not sent");
    XCTAssertNil(failDelegate.error, @"error is non-nil");

    // Test delegate only implementing finish
    GraphDelegateFinish *finishDelegate = [[GraphDelegateFinish alloc] init];
    XCTAssertNoThrow([self failGraphWithDelegate:finishDelegate task:&task error:&error], @"messages the delegate a method it doesn't implement");

    // Test delegate implementing both optional methods
    GraphDelegateFinishAndFail *finishAndFailDelegate = [[GraphDelegateFinishAndFail alloc] init];
    graph = [self failGraphWithDelegate:finishAndFailDelegate task:&task error:&error];

    XCTAssertTrue(finishAndFailDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(error, finishAndFailDelegate.error, @"correct error not passed");
    XCTAssertEqual(finishAndFailDelegate.graph, graph, @"correct graph not passed");
    XCTAssertEqual(finishAndFailDelegate.task, task, @"correct task not passed");
    XCTAssertFalse(finishAndFailDelegate.didReceiveFinish, @"wrong delegate method sent");
 }


#pragma mark - Helper methods

- (TSKTask *)taskExecutingWithDelegate:(id)delegate
{
    XCTestExpectation *didStartExpectation = [self expectationWithDescription:@"did start"];
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [didStartExpectation fulfill];
    }];
    task.delegate = delegate;

    TSKGraph *graph = [[TSKGraph alloc] init];
    [graph addTask:task prerequisites:nil];
    [task start];

    [self waitForExpectationsWithTimeout:1 handler:nil];

    return task;
}


- (TSKGraph *)finishGraphWithDelegate:(id)delegate
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    graph.delegate = delegate;

    XCTestExpectation *didFinishExpectation = [self expectationWithDescription:@"task did finish"];
    TSKTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [task finishWithResult:nil];
        [didFinishExpectation fulfill];
    }];

    [graph addTask:task prerequisites:nil];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    return graph;
}


- (TSKGraph *)failGraphWithDelegate:(id)delegate task:(TSKTask **)task error:(NSError **)error
{
    NSParameterAssert(task);

    TSKGraph *graph = [[TSKGraph alloc] init];
    graph.delegate = delegate;

    XCTestExpectation *didFinishExpectation = [self expectationWithDescription:@"task did finish"];

    if (error) {
        *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
            [task failWithError:*error];
            [didFinishExpectation fulfill];
        }];
    } else {
        *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
            [task failWithError:nil];
            [didFinishExpectation fulfill];
        }];
    }

    [graph addTask:*task prerequisites:nil];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    return graph;
}


@end
