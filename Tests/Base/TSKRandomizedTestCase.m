//
//  TSKRandomizedTestCase.m
//  Task
//
//  Created by Prachi Gauriar on 10/30/2014.
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

const NSTimeInterval kTSKRandomizedTestCaseDateTolerance = 0.1;


#pragma mark -

@implementation TSKRandomizedTestCase

+ (void)setUp
{
    [super setUp];
    srandomdev();
}


- (void)setUp
{
    [super setUp];
    unsigned seed = (unsigned)random();
    NSLog(@"Using seed %d", seed);
    srandom(seed);
    self.notificationCenter = [[NSNotificationCenter alloc] init];
}


- (NSString *)defaultNameForTask:(TSKTask *)task
{
    return [NSString stringWithFormat:@"TSKTask %p", task];
}


#pragma mark -

- (TSKWorkflow *)workflowForNotificationTesting
{
    return [[TSKWorkflow alloc] initWithName:nil operationQueue:nil notificationCenter:self.notificationCenter];
}


- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName task:(TSKTask *)task
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Observe %p %@", task, notificationName]];

    [self observeNotification:notificationName
           notificationCenter:task.workflow.notificationCenter
                       object:task
                  expectation:expectation
                        block:nil];

    return expectation;
}


- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName workflow:(TSKWorkflow *)workflow block:(void (^)(NSNotification *))block
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Observe %p %@", workflow, notificationName]];

    [self observeNotification:notificationName
           notificationCenter:workflow.notificationCenter
                       object:workflow
                  expectation:expectation
                        block:block];

    return expectation;
}


- (void)observeNotification:(NSString *)notificationName
         notificationCenter:(NSNotificationCenter *)notificationCenter
                     object:(id)object
                expectation:(XCTestExpectation *)expectation
                      block:(void (^)(NSNotification *))block
{
    __block BOOL isFulfilled = NO;
    __weak typeof(notificationCenter) weak_notificationCenter = notificationCenter;
    __block id observer = [notificationCenter addObserverForName:notificationName object:object queue:nil usingBlock:^(NSNotification *note) {
        @synchronized (self) {
            if (isFulfilled) {
                return;
            }

            isFulfilled = YES;
        }

        if (block) {
            block(note);
        }

        [expectation fulfill];
        [weak_notificationCenter removeObserver:observer name:notificationName object:object];
    }];
}


#pragma mark -

- (TSKTestTask *)finishingTaskWithLock:(NSLock *)lock
{
    return [self finishingTaskWithLock:lock result:nil];
}


- (TSKTestTask *)finishingTaskWithLock:(NSLock *)lock result:(id)result
{
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [lock lock];
        [task finishWithResult:result];
        [lock unlock];
    }];

    return task;
}


- (TSKTestTask *)failingTaskWithLock:(NSLock *)lock
{
    return [self failingTaskWithLock:lock error:nil];
}


- (TSKTestTask *)failingTaskWithLock:(NSLock *)lock error:(NSError *)error
{
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [lock lock];
        [task failWithError:error];
        [lock unlock];
    }];

    return task;
}

@end
