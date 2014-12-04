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


# pragma mark - Helper Classes

@interface TaskDelegateFinish : NSObject <TSKTaskDelegate>

@property (nonatomic, assign) BOOL didReceiveFinish;
@property (nonatomic, strong) id result;

@end

@implementation TaskDelegateFinish

- (void)task:(TSKTask *)task didFinishWithResult:(id)result
{
    self.didReceiveFinish = YES;
    self.result = result;
}

@end


@interface TaskDelegateFail : NSObject <TSKTaskDelegate>

@property (nonatomic, assign) BOOL didReceiveFail;
@property (nonatomic, strong) NSError *error;

@end

@implementation TaskDelegateFail

- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.didReceiveFail = YES;
    self.error = error;
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
}

@end


#pragma mark - Tests for Delegate Methods

@interface TSKDelegateTestCase : TSKRandomizedTestCase

@end

@implementation TSKDelegateTestCase

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


- (void)testTaskDelegateFinish
{
    TaskDelegateFinish *finishDelegate = [[TaskDelegateFinish alloc] init];
    TSKTask *task = [self taskExecutingWithDelegate:finishDelegate];
    NSString *resultString = UMKRandomUnicodeString();

    [task finishWithResult:resultString];

    XCTAssertTrue(finishDelegate.didReceiveFinish, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(resultString, finishDelegate.result, @"correct result not passed");

    TaskDelegateFail *failDelegate = [[TaskDelegateFail alloc] init];
    task = [self taskExecutingWithDelegate:failDelegate];

    XCTAssertNoThrow([task finishWithResult:resultString], @"messages the delegate a method it doesn't implement");

    TaskDelegateFinishAndFail *finishAndFailDelegate = [[TaskDelegateFinishAndFail alloc] init];
    task = [self taskExecutingWithDelegate:finishAndFailDelegate];

    [task finishWithResult:resultString];

    XCTAssertTrue(finishAndFailDelegate.didReceiveFinish, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(resultString, finishAndFailDelegate.result, @"correct result not passed");
    XCTAssertFalse(finishAndFailDelegate.didReceiveFail, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.error, @"wrong delegate method sent");
}


- (void)testTaskDelegateFail
{
    NSError *error = UMKRandomError();

    TaskDelegateFail *failDelegate = [[TaskDelegateFail alloc] init];
    TSKTask *task = [self taskExecutingWithDelegate:failDelegate];

    [task failWithError:error];

    XCTAssertTrue(failDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(error, failDelegate.error, @"correct error not passed");

    TaskDelegateFinish *finishDelegate = [[TaskDelegateFinish alloc] init];
    task = [self taskExecutingWithDelegate:finishDelegate];

    XCTAssertNoThrow([task failWithError:error], @"messages the delegate a method it doesn't implement");

    TaskDelegateFinishAndFail *finishAndFailDelegate = [[TaskDelegateFinishAndFail alloc] init];
    task = [self taskExecutingWithDelegate:finishAndFailDelegate];

    [task failWithError:error];

    XCTAssertTrue(finishAndFailDelegate.didReceiveFail, @"delegate method not sent to delegate implementing it");
    XCTAssertEqual(error, finishAndFailDelegate.error, @"correct error not passed");
    XCTAssertFalse(finishAndFailDelegate.didReceiveFinish, @"wrong delegate method sent");
    XCTAssertNil(finishAndFailDelegate.result, @"wrong delegate method sent");
}

@end

