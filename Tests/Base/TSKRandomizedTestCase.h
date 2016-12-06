//
//  TSKRandomizedTestCase.h
//  Task
//
//  Created by Prachi Gauriar on 10/30/2014.
//  Copyright (c) 2015 Ticketmaster Entertainment, Inc. All rights reserved.
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

@import XCTest;

#import <Task/Task.h>
#import <URLMock/UMKTestUtilities.h>

#import "TSKTestTask.h"


extern const NSTimeInterval kTSKRandomizedTestCaseDateTolerance;


/*!
 TSKRandomizedTestCases override +setUp to call srandomdev() and -setUp to generate and log a random
 seed value before calling srandom(). Subclasses that override +setUp or -setUp should invoke the
 superclass implementation.

 It also has a notification center that may be used with TSKWorkflows to post notifications on.
 */
@interface TSKRandomizedTestCase : XCTestCase

/*! The notification center that TSKWorkflows can post notifications on. */
@property (nonatomic, strong) NSNotificationCenter *notificationCenter;

/*! 
 @abstract Returns the default name for the specified task.
 @param task The task whose default name will be returned.
 @result The default name for the specified task.
 */
- (NSString *)defaultNameForTask:(TSKTask *)task;

/*!
 @abstract Returns the default name for the specified workflow.
 @param workflow The workflow whose default name will be returned.
 @result The default name for the specified workflow.
 */
- (NSString *)defaultNameForWorkflow:(TSKWorkflow *)workflow;

/*!
 @abstract Returns a new workflow whose notification center is the same as the receiver’s.
 @result A new workflow whose notification center is the same as the receiver’s.
 */
- (TSKWorkflow *)workflowForNotificationTesting;

/*!
 @abstract Creates and returns a new expectation to receive the specified notification from the
     specified task.
 @discussion This causes the receiver to register to observe the specified notification from the
     task’s workflow’s notification center. Once the notification has been observed, the expectation
     is fulfilled.
 @param notificationName The notification to observe.
 @param task The task that will post the notification.
 @result A new expectation that will be fulfilled when the specified task posts the specified 
     notification.
 */
- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName task:(TSKTask *)task;

/*!
 @abstract Creates and returns a new expectation to receive the specified notification from the
     specified workflow.
 @discussion This causes the receiver to register to observe the specified notification from the
     workflow’s notification center. Once the notification has been observed, the expectation
     is fulfilled.
 @param notificationName The notification to observe.
 @param workflow The workflow that will post the notification.
 @param block An optional block to execute upon receiving the notification.
 @result A new expectation that will be fulfilled when the specified workflow posts the specified
     notification.
 */
- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName workflow:(TSKWorkflow *)workflow block:(void (^)(NSNotification *))block;

/*!
 @abstract Creates and returns a task that will lock the specified lock, finish with a nil result,
     and then unlock the specified lock.
 @param lock The lock that the task will lock and unlock.
 @result A task that will finish after acquiring the specified lock.
 */
- (TSKTestTask *)finishingTaskWithLock:(NSLock *)lock;

/*!
 @abstract Creates and returns a task that will lock the specified lock, finish with the specified
     result, and then unlock the specified lock.
 @param lock The lock that the task will lock and unlock.
 @param result The result that that the task will finish with
 @result A task that will finish after acquiring the specified lock.
 */
- (TSKTestTask *)finishingTaskWithLock:(NSLock *)lock result:(id)result;

/*!
 @abstract Creates and returns a task that will lock the specified lock, fail with a nil error,
     and then unlock the specified lock.
 @param lock The lock that the task will lock and unlock.
 @result A task that will fail after acquiring the specified lock.
 */
- (TSKTestTask *)failingTaskWithLock:(NSLock *)lock;

/*!
 @abstract Creates and returns a task that will lock the specified lock, fail with the specified
     error, and then unlock the specified lock.
 @param lock The lock that the task will lock and unlock.
 @param error The error to that the task will fail with
 @result A task that will fail after acquiring the specified lock.
 */
- (TSKTestTask *)failingTaskWithLock:(NSLock *)lock error:(NSError *)error;

/*!
 @abstract Creates and returns a task that will lock the specified lock, cancel itself, and then
     unlock the specified lock.
 @param lock The lock that the task will lock and unlock.
 @result A task that will cancel itself after acquiring the specified lock.
 */
- (TSKTestTask *)cancellingTaskWithLock:(NSLock *)lock;

@end
