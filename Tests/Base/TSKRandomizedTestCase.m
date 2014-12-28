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


- (TSKWorkflow *)workflowForNotificationTesting
{
    return [[TSKWorkflow alloc] initWithName:nil operationQueue:nil notificationCenter:self.notificationCenter];
}


- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName task:(TSKTask *)task
{
    XCTestExpectation *notificationExpectation = [self expectationWithDescription:[NSString stringWithFormat:@"Observe %p %@", task, notificationName]];

    __block id observer = [task.workflow.notificationCenter addObserverForName:notificationName object:task queue:nil usingBlock:^(NSNotification *note) {
        [notificationExpectation fulfill];
        [task.workflow.notificationCenter removeObserver:observer name:notificationName object:task];
    }];

    return notificationExpectation;
}


- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName workflow:(TSKWorkflow *)workflow block:(void (^)(NSNotification *))block
{
    XCTestExpectation *notificationExpectation = [self expectationWithDescription:[NSString stringWithFormat:@"Observe %p %@", workflow, notificationName]];

    __weak typeof(workflow) weak_workflow = workflow;
    __block id observer = [workflow.notificationCenter addObserverForName:notificationName object:workflow queue:nil usingBlock:^(NSNotification *note) {
        if (block) {
            block(note);
        }

        [notificationExpectation fulfill];
        [weak_workflow.notificationCenter removeObserver:observer name:notificationName object:weak_workflow];
    }];

    return notificationExpectation;
}


- (TSKTestTask *)finishingTaskWithLock:(NSLock *)lock
{
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [lock lock];
        [task finishWithResult:nil];
        [lock unlock];
    }];

    return task;
}


- (TSKTestTask *)failingTaskWithLock:(NSLock *)lock
{
    TSKTestTask *task = [[TSKTestTask alloc] initWithBlock:^(TSKTask *task) {
        [lock lock];
        [task failWithError:nil];
        [lock unlock];
    }];

    return task;
}

@end
