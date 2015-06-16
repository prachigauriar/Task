//
//  TSKWorkflowTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/4/14.
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

#import "TSKRandomizedTestCase.h"

#import <URLMock/UMKMessageCountingProxy.h>


#pragma mark Test Delegate 

@interface TSKTestWorkflowDelegate : NSObject <TSKWorkflowDelegate>

@property (nonatomic, strong) TSKWorkflow *workflow;
@property (nonatomic, strong) TSKTask *task;
@property (nonatomic, strong) NSError *error;

@end


@implementation TSKTestWorkflowDelegate

- (void)workflowDidFinish:(TSKWorkflow *)workflow
{
    self.workflow = workflow;
}


- (void)workflow:(TSKWorkflow *)workflow task:(TSKTask *)task didFailWithError:(NSError *)error
{
    self.workflow = workflow;
    self.task = task;
    self.error = error;
}


- (void)workflow:(TSKWorkflow *)workflow taskDidCancel:(TSKTask *)task
{
    self.workflow = workflow;
    self.task = task;
}

@end


#pragma mark -

@interface TSKWorkflowTestCase : TSKRandomizedTestCase

- (void)testInit;
- (void)testAddTasks;
- (void)testAddTaskErrorCases;
- (void)testHasUnfinishedTasks;
- (void)testHasFailedTasks;
- (void)testStartNoPrerequisites;
- (void)testStartOnePrerequisite;
- (void)testStartMultiplePrerequisites;
- (void)testStartMultipleDependents;
- (void)testReset;
- (void)testRetry;
- (void)testCancel;

- (void)testWorkflowDelegateFinish;
- (void)testWorkflowDelegateFail;
- (void)testWorkflowDelegateCancel;

@end


@implementation TSKWorkflowTestCase

- (void)testInit
{
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    XCTAssertNotNil(workflow, @"returns nil");
    XCTAssertEqualObjects(workflow.allTasks, [NSSet set]);
    XCTAssertEqualObjects(workflow.name, ([NSString stringWithFormat:@"TSKWorkflow %p", workflow]), @"name not set to default");
    XCTAssertNotNil(workflow.operationQueue, @"operation queue not set to default");
    XCTAssertEqualObjects(workflow.operationQueue.name, ([NSString stringWithFormat:@"com.ticketmaster.TSKWorkflow.TSKWorkflow %p", workflow]),
                          @"name not set to default");
    XCTAssertEqualObjects(workflow.notificationCenter, [NSNotificationCenter defaultCenter], @"notificationCenter not set to default");

    NSString *workflowName = UMKRandomUnicodeString();
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSString *queueName = queue.name;
    workflow = [[TSKWorkflow alloc] initWithName:workflowName operationQueue:queue];
    XCTAssertNotNil(workflow, @"returns nil");
    XCTAssertEqualObjects(workflow.allTasks, [NSSet set]);
    XCTAssertEqualObjects(workflow.name, workflowName, @"name is set incorrectly");
    XCTAssertEqualObjects(workflow.operationQueue, queue, @"operation queue is set incorrectly");
    XCTAssertEqualObjects(workflow.operationQueue.name, queueName, @"operation queue name changed");
    XCTAssertEqualObjects(workflow.notificationCenter, [NSNotificationCenter defaultCenter], @"notificationCenter not set to default");

    workflow = [[TSKWorkflow alloc] initWithName:workflowName operationQueue:queue notificationCenter:self.notificationCenter];
    XCTAssertNotNil(workflow, @"returns nil");
    XCTAssertEqualObjects(workflow.allTasks, [NSSet set]);
    XCTAssertEqualObjects(workflow.name, workflowName, @"name is set incorrectly");
    XCTAssertEqualObjects(workflow.operationQueue, queue, @"operation queue is set incorrectly");
    XCTAssertEqualObjects(workflow.operationQueue.name, queueName, @"operation queue name changed");
    XCTAssertEqualObjects(workflow.notificationCenter, self.notificationCenter, @"notificationCenter not set to default");
}


- (void)testAddTasks
{
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    TSKTask *task1 = [[TSKTask alloc] init];
    [workflow addTask:task1 prerequisites:nil];
    XCTAssertEqualObjects([workflow prerequisiteTasksForTask:task1], [NSSet set], @"prerequisites not set");
    XCTAssertEqualObjects([workflow dependentTasksForTask:task1], [NSSet set], @"dependents not set");

    TSKTask *task2 = [[TSKTask alloc] init];
    [workflow addTask:task2 prerequisites:nil];
    XCTAssertEqualObjects([workflow prerequisiteTasksForTask:task2], [NSSet set], @"prerequisites not set");
    XCTAssertEqualObjects([workflow dependentTasksForTask:task2], [NSSet set], @"dependents not set");

    TSKTask *dependent = [[TSKTask alloc] init];
    [workflow addTask:dependent prerequisiteTasks:[NSSet setWithObject:task1] keyedPrerequisiteTasks:@{ @"a" : task2}];

    XCTAssertEqualObjects([workflow prerequisiteTasksForTask:dependent], ([NSSet setWithObjects:task1, task2, nil]), @"prerequisites not set property");
    XCTAssertEqualObjects([workflow unkeyedPrerequisiteTasksForTask:dependent], [NSSet setWithObject:task1], @"unkeyed prerequisites not set property");
    XCTAssertEqualObjects([workflow keyedPrerequisiteTasksForTask:dependent], @{ @"a" : task2 }, @"keyed prerequisites not set property");

    XCTAssertEqualObjects([workflow dependentTasksForTask:task1], [NSSet setWithObject:dependent], @"dependents not set property");
    XCTAssertEqualObjects([workflow dependentTasksForTask:task2], [NSSet setWithObject:dependent], @"dependents not set property");
    XCTAssertEqualObjects([workflow allTasks], ([NSSet setWithObjects:task1, task2, dependent, nil]), @"all tasks not set property");
    XCTAssertEqualObjects([workflow tasksWithNoPrerequisiteTasks], ([NSSet setWithObjects:task1, task2, nil]),
                          @"tasksWithNoPrerequisiteTasks not set correctly");
    XCTAssertEqualObjects([workflow tasksWithNoDependentTasks], [NSSet setWithObject:dependent], @"tasksWithNoDependentTasks not set correctly");
}


- (void)testAddTaskErrorCases
{
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    TSKTask *task = [[TSKTask alloc] init];
    [workflow addTask:task prerequisites:nil];
    XCTAssertThrows([workflow addTask:task prerequisites:nil], @"adding a task to the same workflow twice does not throw an exception");

    TSKWorkflow *otherWorkflow = [[TSKWorkflow alloc] init];
    XCTAssertThrows([otherWorkflow addTask:task prerequisites:nil], @"adding a task to a second workflow does not throw an exception");

    TSKTask *prerequisiteTask = [[TSKTask alloc] init];
    TSKTask *dependentTask = [[TSKTask alloc] init];

    XCTAssertThrows(([workflow addTask:dependentTask prerequisites:prerequisiteTask, nil]),
                    @"workflow allows a task to be added before its prerequisite is added");

    TSKTestTask *requiredKeysTask = [self finishingTaskWithLock:nil];
    requiredKeysTask.requiredPrerequisiteKeys = UMKGeneratedSetWithElementCount(random() % 5 + 2, ^id{
        return UMKRandomUnsignedNumber();
    });

    XCTAssertThrows([workflow addTask:requiredKeysTask keyedPrerequisiteTasks:@{ [requiredKeysTask.requiredPrerequisiteKeys anyObject] : task }],
                    @"workflow allows a task to be added without all its required keys");
}


- (void)testHasUnfinishedTasks
{
    // NOTE This property is also tested in other methods to test in other scenarios (e.g., retry, cancel)
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    TSKTestTask *task = [self finishingTaskWithLock:willFinishLock];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"hasUnfinishedTasks is false");

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [willFinishLock unlock];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(workflow.hasUnfinishedTasks, @"hasUnfinishedTasks is true");

    workflow = [[TSKWorkflow alloc] init];
    task = [self failingTaskWithLock:nil];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidFailNotification object:task handler:nil];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"hasUnfinishedTasks is false");
}


- (void)testHasFailedTasks
{
    // NOTE This property is also tested in other methods to test in other scenarios (e.g., retry, cancel)
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [[TSKWorkflow alloc] init];
    TSKTestTask *task = [self failingTaskWithLock:willFinishLock];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(workflow.hasFailedTasks, @"hasFailedTasks is true");

    [self expectationForNotification:TSKTestTaskDidFailNotification object:task handler:nil];
    [willFinishLock unlock];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(workflow.hasFailedTasks, @"hasFailedTasks is false");

    workflow = [[TSKWorkflow alloc] init];
    task = [self finishingTaskWithLock:nil];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(workflow.hasFailedTasks, @"hasFailedTasks is true");
}


- (void)testStartNoPrerequisites
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [[TSKTestTask alloc] init];
    [workflow addTask:task prerequisites:nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, "state is not ready");

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateExecuting, "state is not executing");
}


- (void)testStartOnePrerequisite
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self finishingTaskWithLock:willFinishLock];
    TSKTestTask *dependentTask = [self finishingTaskWithLock:willFinishLock];
    [workflow addTask:task prerequisites:nil];
    [workflow addTask:dependentTask prerequisites:task, nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task starts
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // First task is waiting for lock and finishes
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");

    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidFinishNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // Dependent task is waiting for lock and finishes
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(dependentTask.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is true");
}


- (void)testStartOneKeyedPrerequisite
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self finishingTaskWithLock:willFinishLock];
    TSKTestTask *dependentTask = [self finishingTaskWithLock:willFinishLock];
    [workflow addTask:task prerequisites:nil];

    NSString *prerequisiteKey = UMKRandomIdentifierString();
    [workflow addTask:dependentTask keyedPrerequisiteTasks:@{ prerequisiteKey : task }];

    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task starts
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // First task is waiting for lock and finishes
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");

    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidFinishNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // Dependent task is waiting for lock and finishes
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(dependentTask.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is true");
}


- (void)testStartMultiplePrerequisites
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task1 = [self finishingTaskWithLock:willFinishLock];
    TSKTestTask *task2 = [self finishingTaskWithLock:nil];
    TSKTestTask *dependentTask = [self finishingTaskWithLock:willFinishLock];
    [workflow addTask:task1 prerequisites:nil];
    [workflow addTask:task2 prerequisites:nil];
    [workflow addTask:dependentTask prerequisiteTasks:[NSSet setWithObject:task1] keyedPrerequisiteTasks:@{ UMKRandomIdentifierString() : task2 }];

    XCTAssertEqual(task1.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(task2.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task2 handler:nil]; // task2 has no lock, so it will finish
    [willFinishLock lock];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task1 starts and task2 finishes
    XCTAssertEqual(task1.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(task2.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    // task1 is waiting for lock and finishes, then dependentTask begins executing
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task1.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(task2.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");

    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidFinishNotification object:dependentTask handler:nil];
    [willFinishLock unlock];
    [self waitForExpectationsWithTimeout:1 handler:nil];  // dependentTask is waiting for lock and finishes
    XCTAssertEqual(dependentTask.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is true");
}


- (void)testStartMultipleDependents
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self finishingTaskWithLock:willFinishLock];
    TSKTestTask *dependentTask1 = [self finishingTaskWithLock:willFinishLock];
    TSKTestTask *dependentTask2 = [self finishingTaskWithLock:willFinishLock];

    [workflow addTask:task prerequisites:nil];
    [workflow addTask:dependentTask1 prerequisites:task, nil];
    [workflow addTask:dependentTask2 prerequisites:task, nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, @"state is not ready");
    XCTAssertEqual(dependentTask1.state, TSKTaskStatePending, @"dependent state is not pending");
    XCTAssertEqual(dependentTask2.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until task1 starts and task2 finishes
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask1.state, TSKTaskStatePending, @"dependent state is not pending");
    XCTAssertEqual(dependentTask2.state, TSKTaskStatePending, @"dependent state is not pending");

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:dependentTask1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:dependentTask2 handler:nil];
    [willFinishLock unlock];
    // task is waiting for lock and finishes, then dependents begin executing
    [willFinishLock lock];
    [self waitForExpectationsWithTimeout:1 handler:nil]; // wait until dependentTask starts
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertEqual(dependentTask1.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertEqual(dependentTask2.state, TSKTaskStateExecuting, @"state is not executing");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");

    [self expectationForNotification:TSKTestTaskDidFinishNotification object:dependentTask1 handler:nil];
    [self expectationForNotification:TSKTestTaskDidFinishNotification object:dependentTask2 handler:nil];
    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];
    [willFinishLock unlock];
    // dependentTasks are waiting for lock and finish
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(dependentTask1.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertEqual(dependentTask2.state, TSKTaskStateFinished, "state is not finished");
    XCTAssertFalse(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is true");
}


- (void)testReset
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self finishingTaskWithLock:willFinishLock];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];

    // Put task in typical state for reset
    [self expectationForNotification:TSKTestTaskDidFinishNotification object:task handler:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateFinished, @"state is not finished");
    XCTAssertFalse(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is true");

    // Test that workflow sends reset to its task
    [self expectationForNotification:TSKWorkflowWillResetNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidResetNotification object:task handler:nil];
    [willFinishLock lock];
    [workflow reset];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssert((task.state == TSKTaskStatePending || task.state == TSKTaskStateReady), @"state is not pending or ready");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");
    [willFinishLock unlock];
}


- (void)testResetWithReadyDependent
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self finishingTaskWithLock:nil];
    TSKTestTask *dependentTask = [self failingTaskWithLock:nil];

    [workflow addTask:task prerequisites:nil];
    [workflow addTask:dependentTask prerequisites:task, nil];

    // Run workflow so that task finishes and dependentTask fails
    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTaskDidFailNotification task:dependentTask];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual(task.state, TSKTaskStateFinished, @"task state is not finished");
    XCTAssertEqual(dependentTask.state, TSKTaskStateFailed, @"dependent task state is not failed");

    // Reset dependentTask. Should be in ready state
    [self expectationForNotification:TSKTaskDidResetNotification task:dependentTask];
    [dependentTask reset];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual(dependentTask.state, TSKTaskStateReady, @"dependent task state is not ready after reset");

    // Reset task. Should be in ready state. dependentTask should also be reset and be in pending state.
    [self expectationForNotification:TSKTaskDidResetNotification task:task];
    [self expectationForNotification:TSKTaskDidResetNotification task:dependentTask];
    [task reset];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual(task.state, TSKTaskStateReady, @"task state is not ready after reset");
    XCTAssertEqual(dependentTask.state, TSKTaskStatePending, @"dependentTask state is not pending after reset");
}


- (void)testRetry
{
    NSLock *willFailLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self failingTaskWithLock:willFailLock];
    [workflow addTask:task prerequisites:nil];

    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKWorkflowTaskDidFailNotification workflow:workflow block:^(NSNotification *note) {
        XCTAssertNotNil(note, @"notification has nil userInfo dictionary");
        XCTAssertEqual(note.userInfo[TSKWorkflowTaskKey], task, @"notification has incorrect task");
    }];

    // Put task in typical state for retry
    [self expectationForNotification:TSKTestTaskDidFailNotification object:task handler:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateFailed, @"state is not failed");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");
    XCTAssertTrue(workflow.hasFailedTasks, @"workflow.hasFailedTasks is not true");

    // Test that workflow sends retry to its task
    [self expectationForNotification:TSKWorkflowWillRetryNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidRetryNotification object:task handler:nil];
    [willFailLock lock];
    [workflow retry];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssert((task.state == TSKTaskStateExecuting || task.state == TSKTaskStateReady), @"state is not ready or executing");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");
    XCTAssertFalse(workflow.hasFailedTasks, @"workflow.hasFailedTasks did not update with retry");
    [willFailLock unlock];
}


- (void)testCancel
{
    NSLock *willFinishLock = [[NSLock alloc] init];
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    TSKTestTask *task = [self finishingTaskWithLock:willFinishLock];
    [workflow addTask:task prerequisites:nil];

    // Put task mid-execution
    [self expectationForNotification:TSKWorkflowWillStartNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidStartNotification object:task handler:nil];
    [willFinishLock lock];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateExecuting, @"state is not executing");

    // Test that workflow sends cancel to its task
    [self expectationForNotification:TSKWorkflowWillCancelNotification workflow:workflow block:nil];
    [self expectationForNotification:TSKTestTaskDidCancelNotification object:task handler:nil];
    [workflow cancel];
    [willFinishLock unlock];
    // Task is waiting for lock and finishes executing. However, it should have received -cancel and thus not honor finish
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqual(task.state, TSKTaskStateCancelled, @"cancel not sent to task");
    XCTAssertTrue(workflow.hasUnfinishedTasks, @"workflow.hasUnfinishedTasks is not true");
    XCTAssertFalse(workflow.hasFailedTasks, @"workflow.hasFailedTasks is not false");
}


#pragma mark -

- (TSKTask *)cancelledTaskInWorkflowWithDelegate:(id)delegate
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    workflow.delegate = delegate;

    XCTestExpectation *didCancelExpectation = [self expectationWithDescription:@"task did cancel"];
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [task cancel];
        [didCancelExpectation fulfill];
    }];

    [workflow addTask:task prerequisites:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    return task;
}


- (TSKTask *)failedTaskInWorkflowWithDelegate:(id)delegate error:(NSError *)error
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
    workflow.delegate = delegate;

    XCTestExpectation *didFinishExpectation = [self expectationWithDescription:@"task did fail"];
    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        [task failWithError:error];
        [didFinishExpectation fulfill];
    }];

    [workflow addTask:task prerequisites:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    return task;
}


- (TSKWorkflow *)finishedWorkflowWithDelegate:(id)delegate
{
    TSKWorkflow *workflow = [self workflowForNotificationTesting];
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


- (void)testWorkflowDelegateFinish
{
    // Message-counting delegate
    id delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestWorkflowDelegate alloc] init]];
    TSKWorkflow *workflow = [self finishedWorkflowWithDelegate:delegate];

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(workflowDidFinish:)],
                   @"delegate received workflowDidFinish: incorrect number of times");
    XCTAssertEqualObjects([delegate workflow], workflow, @"delegate received incorrect workflow parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflow:task:didFailWithError:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflow:taskDidCancel:)], @"delegate received unexpected selector");

    // Object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    XCTAssertNoThrow([self finishedWorkflowWithDelegate:delegate], @"delegate that does not implement messages is sent unexpected selector");

    // Empty workflow with message-counting delegate
    delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestWorkflowDelegate alloc] init]];
    workflow = [self workflowForNotificationTesting];
    workflow.delegate = delegate;

    [self expectationForNotification:TSKWorkflowDidFinishNotification workflow:workflow block:nil];
    [workflow start];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(workflowDidFinish:)],
                   @"delegate received workflowDidFinish: incorrect number of times");
    XCTAssertEqualObjects([delegate workflow], workflow, @"delegate received incorrect workflow parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflow:task:didFailWithError:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflow:taskDidCancel:)], @"delegate received unexpected selector");

    // Empty workflow with object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    workflow = [self workflowForNotificationTesting];
    workflow.delegate = delegate;

    XCTAssertNoThrow([workflow start], @"delegate that does not implement messages is sent unexpected selector");
}


- (void)testWorkflowDelegateFail
{
    NSError *error = UMKRandomError();

    // Message-counting delegate
    id delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestWorkflowDelegate alloc] init]];
    TSKTask *task = [self failedTaskInWorkflowWithDelegate:delegate error:error];
    TSKWorkflow *workflow = task.workflow;

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(workflow:task:didFailWithError:)],
                   @"delegate received workflow:task:didFailWithError: incorrect number of times");
    XCTAssertEqualObjects([delegate workflow], workflow, @"delegate received incorrect workflow parameter");
    XCTAssertEqualObjects([delegate task], task, @"delegate received incorrect task parameter");
    XCTAssertEqualObjects([delegate error], error, @"delegate received incorrect error parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflowDidFinish:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflow:taskDidCancel:)], @"delegate received unexpected selector");

    // Object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    XCTAssertNoThrow([self failedTaskInWorkflowWithDelegate:delegate error:error], @"delegate that does not implement messages is sent unexpected selector");
}


- (void)testWorkflowDelegateCancel
{
    // Message-counting delegate
    id delegate = [UMKMessageCountingProxy messageCountingProxyWithObject:[[TSKTestWorkflowDelegate alloc] init]];
    TSKTask *task = [self cancelledTaskInWorkflowWithDelegate:delegate];
    TSKWorkflow *workflow = task.workflow;

    XCTAssertEqual((NSUInteger)1, [delegate receivedMessageCountForSelector:@selector(workflow:taskDidCancel:)],
                   @"delegate received workflow:taskDidCancel: incorrect number of times");
    XCTAssertEqualObjects([delegate workflow], workflow, @"delegate received incorrect workflow parameter");
    XCTAssertEqualObjects([delegate task], task, @"delegate received incorrect task parameter");

    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflowDidFinish:)], @"delegate received unexpected selector");
    XCTAssertFalse([delegate hasReceivedSelector:@selector(workflow:task:didFailWithError:)], @"delegate received unexpected selector");

    // Object that does not implement delegate messages
    delegate = [[NSObject alloc] init];
    XCTAssertNoThrow([self cancelledTaskInWorkflowWithDelegate:delegate], @"delegate that does not implement messages is sent unexpected selector");
}

@end
