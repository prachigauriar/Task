//
//  TSKWorkflow.h
//  Task
//
//  Created by Prachi Gauriar on 10/14/2014.
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

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

#pragma mark Constants

/*!
 @abstract Notification posted when all a workflow’s tasks finished.
 @discussion This notification is posted immediately after the workflow’s delegate is sent the
     ‑workflowDidFinish: message. The object of the notification is the workflow. It has no userInfo
     dictionary.
 */
extern NSNotificationName const TSKWorkflowDidFinishNotification;

/*!
 @abstract Notification posted when a workflow’s task is cancelled.
 @discussion This notification is posted immediately after the workflow’s delegate is sent the
     ‑workflow:taskDidCancel: message. The object of the notification is the workflow. Its
     userInfo dictionary contains a single key, TSKWorkflowTaskKey, whose value is the task that
     was cancelled.
 */
extern NSNotificationName const TSKWorkflowTaskDidCancelNotification;

/*!
 @abstract Notification posted when a workflow’s task fails.
 @discussion This notification is posted immediately after the workflow’s delegate is sent the
     ‑workflow:task:didFailWithError: message. The object of the notification is the workflow. Its
     userInfo dictionary contains a single key, TSKWorkflowTaskKey, whose value is the task that
     failed.
 */
extern NSNotificationName const TSKWorkflowTaskDidFailNotification;

/*!
 @abstract Notification posted when a workflow is about to cancel its tasks.
 @discussion This notification is posted immediately before the workflow’s tasks are sent the
     ‑cancel message. The object of the notification is the workflow. It has no userInfo dictionary.
 */
extern NSNotificationName const TSKWorkflowWillCancelNotification;

/*!
 @abstract Notification posted when a workflow about to reset its tasks.
 @discussion This notification is posted immediately before the workflow’s tasks are sent the ‑reset
     message. The object of the notification is the workflow. It has no userInfo dictionary.
 */
extern NSNotificationName const TSKWorkflowWillResetNotification;

/*!
 @abstract Notification posted when a workflow about to retry its tasks.
 @discussion This notification is posted immediately before the workflow’s tasks are sent the ‑retry
     message. The object of the notification is the workflow. It has no userInfo dictionary.
 */
extern NSNotificationName const TSKWorkflowWillRetryNotification;

/*!
 @abstract Notification posted when a workflow is about to start its tasks.
 @discussion This notification is posted immediately before the workflow’s tasks are sent the ‑start
     message. The object of the notification is the workflow. It has no userInfo dictionary.
 */
extern NSNotificationName const TSKWorkflowWillStartNotification;

/*!
 @abstract Notification userInfo key whose value is a TSKTask object pertaining to the workflow 
     notification.
 @discussion This key is present in userInfo dictionaries for TSKWorkflowDidCancelNotification and
     TSKWorkflowDidFailNotification.
 */
extern NSString *const TSKWorkflowTaskKey;


#pragma mark -

@class TSKTask;
@protocol TSKWorkflowDelegate;

/*!
 Instances of TSKWorkflow, or simply task workflows, provide execution contexts for tasks and keep
 track of prerequisite and dependent relationships between them. Tasks cannot be executed without
 first being added to a workflow. Once a task is added to a workflow, it cannot be placed in another
 workflow.

 Every task workflow has an operation queue on which its tasks ‑main methods are enqueued.

 Task workflows also have the ability to be started, canceled, or retried, which simply sends the
 appropriate message to those tasks in the workflow that have no prerequisites. At that point, the
 messages will propagate throughout the workflow.

 Every TSKWorkflow has an optional delegate that can be informed when all the workflow’s tasks
 finish successfully or any of the tasks fail. See the documentation for TSKWorkflowDelegate for
 more information.
*/
@interface TSKWorkflow : NSObject

/*!
 @abstract The task workflow’s name.
 @discussion The default value of this property is “TSKWorkflow «id»”, where «id» is the memory
     address of the task workflow.
 */
@property (nonatomic, copy, null_resettable) NSString *name;

/*! The task workflow’s delegate. */
@property (nonatomic, weak, nullable) id<TSKWorkflowDelegate> delegate;

/*!
 @abstract The task workflow’s operation queue.
 @discussion If no operation queue is provided upon initialization, a queue will be created for the
     task workflow with the default quality of service and maximum concurrent operations count. Its
     name will be of the form “com.ticketmaster.TSKWorkflow.«name»”, where «name» is the name of the
     task workflow.
 */
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

/*!
 @abstract The task workflow’s notification center.
 @discussion All notifications posted by the workflow and its tasks will be posted to this
     notification center. By default, this is the default notification center.
 */
@property (nonatomic, strong, readonly) NSNotificationCenter *notificationCenter;

/*! The task workflow’s current set of tasks. */
@property (nonatomic, copy, readonly) NSSet<TSKTask *> *allTasks;

/*! The set of tasks currently in the workflow that have no prerequisite tasks. */
@property (nonatomic, copy, readonly) NSSet<TSKTask *> *tasksWithNoPrerequisiteTasks;

/*! The set of tasks currently in the workflow that have no dependent tasks. */
@property (nonatomic, copy, readonly) NSSet<TSKTask *> *tasksWithNoDependentTasks;


#pragma mark - Initializers

/*!
 @abstract Initializes a newly created TSKWorkflow instance with the specified name.
 @discussion A new operation queue will be created for the task workflow with the default quality of
     service and maximum concurrent operations count. The queue’s name will be of the form
     “com.ticketmaster.TSKWorkflow.«name»”, where «name» is the name of the task workflow.
 @param name The name of the task workflow. If nil, the instance’s name will be set to 
     “TSKWorkflow «id»”, where «id» is the memory address of the task.
 @result A newly initialized TSKWorkflow instance with the specified name.
 */
- (instancetype)initWithName:(nullable NSString *)name;

/*!
 @abstract Initializes a newly created TSKWorkflow instance with the specified operation queue.
 @discussion The task workflow will have a name of “TSKWorkflow «id»”, where «id» is the memory
     address of the task workflow.
 @param operationQueue The operation queue the workflow’s tasks will use to execute their ‑main
     methods. If nil, a new operation queue will be created for the task workflow with the default
     quality of service and maximum concurrent operations count. The queue’s name will be of the
     form “com.ticketmaster.TSKWorkflow.«name»”, where «name» is the name of the task workflow.
 @result A newly initialized TSKWorkflow instance with the specified operation queue.
 */
- (instancetype)initWithOperationQueue:(nullable NSOperationQueue *)operationQueue;

/*!
 @abstract Initializes a newly created TSKWorkflow instance with the specified name and operation
     queue.
 @param name The name of the task workflow. If nil, the instance’s name will be set to
     “TSKWorkflow «id»”, where «id» is the memory address of the task.
 @param operationQueue The operation queue the workflow’s tasks will use to execute their ‑main
     methods. If nil, a new operation queue will be created for the task workflow with the default
     quality of service and maximum concurrent operations count. The queue’s name will be of the
     form “com.ticketmaster.TSKWorkflow.«name»”, where «name» is the name of the task workflow.
 @result A newly initialized TSKWorkflow instance with the specified name and operation queue.
 */
- (instancetype)initWithName:(nullable NSString *)name operationQueue:(nullable NSOperationQueue *)operationQueue;

/*!
 @abstract Initializes a newly created TSKWorkflow instance with the specified name, operation
     queue, and notification center.
 @discussion This is the class’s designated initializer.
 @param name The name of the task workflow. If nil, the instance’s name will be set to
     “TSKWorkflow «id»”, where «id» is the memory address of the task.
 @param operationQueue The operation queue the workflow’s tasks will use to execute their ‑main
     methods. If nil, a new operation queue will be created for the task workflow with the default
     quality of service and maximum concurrent operations count. The queue’s name will be of the
     form “com.ticketmaster.TSKWorkflow.«name»”, where «name» is the name of the task workflow.
 @param notificationCenter The notification center the workflow and its tasks will use to post 
     notifications. If nil, the default notification center will be used.
 @result A newly initialized TSKWorkflow instance with the specified name, operation queue,
     and notification center.
 */
- (instancetype)initWithName:(nullable NSString *)name
              operationQueue:(nullable NSOperationQueue *)operationQueue
          notificationCenter:(nullable NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;


#pragma mark - Adding Tasks

/*!
 @abstract Adds the specified task to the task workflow with the specified set of prerequisite tasks.
 @discussion This is equivalent to invoking ‑addTask:prerequisiteTasks:keyedPrerequisiteTasks: with
     a nil keyedPrerequisiteTasks parameter.
 @param task The task to add. May not be nil. May not be a member of any other task workflow.
 @param prerequisiteTasks The task’s prerequisite tasks. If nil, the task will have no prerequisite
     tasks. Otherwise, each task in the set must have already been added to the workflow.
 */
- (void)addTask:(TSKTask *)task prerequisiteTasks:(nullable NSSet<TSKTask *> *)prerequisiteTasks NS_SWIFT_NAME(add(_:prerequisites:));

/*!
 @abstract Adds the specified task to the task workflow with the specified dictionary of keyed 
     prerequisite tasks.
 @discussion This is equivalent to invoking ‑addTask:prerequisiteTasks:keyedPrerequisiteTasks: with
     a nil prerequisiteTasks parameter.
 @param task The task to add. May not be nil. May not be a member of any other task workflow.
 @param keyedPrerequisiteTasks A dictionary that maps the task’s prerequisite keys to their 
     corresponding task. If nil, the task will have no keyed prerequisite tasks. Otherwise, each task
     in the dictionary must have already been added to the workflow.
 */
-        (void)addTask:(TSKTask *)task
keyedPrerequisiteTasks:(nullable NSDictionary<id<NSCopying>, TSKTask *> *)keyedPrerequisiteTasks NS_SWIFT_NAME(add(_:keyedPrerequisites:));

/*!
 @abstract Adds the specified task to the task workflow with the specified prerequisite and keyed
     prerequisite tasks.
 @discussion The task’s workflow property is set to the task, and its prerequisite and keyed
     prerequisite tasks are set to the ones specified. Furthermore, for each prerequisite task —
     keyed or otherwise — the task is added to the prerequisite’s set of dependent tasks. If the 
     task has any prerequisites, its state is set to pending.

     This is not a thread-safe operation. This method should only execute on one thread at a time.
 @param task The task to add. May not be nil. May not be a member of any other task workflow.
 @param prerequisiteTasks The task’s prerequisite tasks. If nil, the task will have no unkeyed
     prerequisite tasks. Otherwise, each task in the set must have already been added to the workflow.
 @param keyedPrerequisiteTasks A dictionary that maps the task’s prerequisite keys to their
     corresponding task. If nil, the task will have no keyed prerequisite tasks. Otherwise, each task
     in the dictionary must have already been added to the workflow.
 */
-        (void)addTask:(TSKTask *)task
     prerequisiteTasks:(nullable NSSet<TSKTask *> *)prerequisiteTasks
keyedPrerequisiteTasks:(nullable NSDictionary<id<NSCopying>, TSKTask *> *)keyedPrerequisiteTasks NS_SWIFT_NAME(add(_:prerequisites:keyedPrerequisites:));

/*!
 @abstract Adds the specified task to the task workflow with the specified list of prerequisite tasks.
 @discussion This method is a convenient shorthand for invoking ‑addTask:prerequisiteTasks:. It is 
     equivalent to the following:
 
         [workflow addTask:task prerequisiteTasks:[NSSet setWithObjects:prerequisiteTask1, ...]];
 @param task The task to add. May not be nil. May not be a member of any other task workflow.
 @param prerequisiteTask1 ... The task’s prerequisite tasks as a nil-terminated list. Each task in
     the set must have already been added to the workflow.
 */
- (void)addTask:(TSKTask *)task prerequisites:(nullable TSKTask *)prerequisiteTask1, ... NS_REQUIRES_NIL_TERMINATION;


#pragma mark - Getting Related Tasks

/*!
 @abstract Returns the set of prerequisite tasks for the specified task.
 @discussion This is the union of the task’s keyed and unkeyed prerequisite tasks.
 @param task The task.
 @result The set of prerequisite tasks for the specified task. Returns nil if the task is not in the
     workflow.
 */
- (nullable NSSet<TSKTask *> *)prerequisiteTasksForTask:(TSKTask *)task NS_SWIFT_NAME(prerequisites(for:));

/*! 
 @abstract Returns the set of unkeyed prerequisite tasks for the specified task.
 @param task The task.
 @result The set of unkeyed prerequisite tasks for the specified task. Returns nil if the task is not
     in the workflow.
 */
- (nullable NSSet<TSKTask *> *)unkeyedPrerequisiteTasksForTask:(TSKTask *)task NS_SWIFT_NAME(unkeyedPrerequisites(for:));

/*!
 @abstract Returns the keyed prerequisite tasks for the specified task.
 @param task The task.
 @result A dictionary that maps the keys of the specified task’s keyed prerequisites to their 
     corresponding tasks. Returns nil if the task is not in the workflow.
 */
- (nullable NSDictionary<id<NSCopying>, TSKTask *> *)keyedPrerequisiteTasksForTask:(TSKTask *)task NS_SWIFT_NAME(keyedPrerequisites(for:));

/*!
 @abstract Returns the set of dependent tasks for the specified task.
 @param task The task.
 @result The set of dependent tasks for the specified task. Returns nil if the task is not in the
     workflow.
 */
- (nullable NSSet<TSKTask *> *)dependentTasksForTask:(TSKTask *)task NS_SWIFT_NAME(dependents(for:));


#pragma mark - Workflow State

/*!
 @abstract Sends ‑start to every prerequisite-less task in the workflow.
 @discussion This serves to begin execution of the tasks in the workflow. After the initial set of
     tasks finish successfully, they will automatically invoke ‑start on their dependent tasks and
     so on until all tasks have finished successfully. If no tasks have been added to the workflow, 
     this will immediately send ‑workflowDidFinish: to the delegate.
 */
- (void)start;

/*!
 @abstract Sends ‑cancel to every prerequisite-less task in the workflow.
 @discussion This serves to mark all the tasks in the workflow as cancelled. The initial set of
     tasks will propagate the cancellation to their dependent tasks and so on until all tasks that
     can be cancelled will be.
 */
- (void)cancel;

/*!
 @abstract Sends ‑reset to every prerequisite-less task in the workflow.
 @discussion This serves to reset all the tasks in the workflow. The initial set of tasks will
     propagate the reset to their dependent tasks and so on until all tasks that can be reset will
     be.
 */
- (void)reset;

/*!
 @abstract Sends ‑retry to every prerequisite-less task in the workflow.
 @discussion This serves to retry all the tasks in the workflow that have failed. The initial set of
     tasks will propagate the retry to their dependent tasks and so on until all tasks that
     can be retried will be.
 */
- (void)retry;

/*!
 @abstract Returns whether the workflow has any unfinished tasks.
 @discussion This is not key-value observable.
 @result Whether the workflow has any unfinished tasks.
 */
- (BOOL)hasUnfinishedTasks;

/*!
 @abstract Returns whether the workflow has any failed tasks.
 @discussion This is not key-value observable.
 @result Whether the workflow has any failed tasks.
 */
- (BOOL)hasFailedTasks;

@end


#pragma mark - Workflow Delegate Protocol

/*!
 The TSKWorkflowDelegate protocol defines an interface via which a workflow’s delegate can perform
 specialized actions when all the tasks in a workflow finish successfully or if a single task fails.
 */
@protocol TSKWorkflowDelegate <NSObject>

@optional

/*!
 @abstract Sent to the delegate when all a workflow’s tasks finish successfully.
 @discussion This is invoked after individual task delegates receive ‑task:didFinishWithResult:.
 @param workflow The workflow whose tasks finished.
 */
- (void)workflowDidFinish:(TSKWorkflow *)workflow;

/*!
 @abstract Sent to the delegate when one of a workflow’s tasks fail.
 @discussion This is invoked after the task’s delegate receives ‑task:didFailWithError:.
 @param workflow The workflow that contains the task.
 @param task The task that failed.
 @param error An error containing the reason the task failed. May be nil.
 */
- (void)workflow:(TSKWorkflow *)workflow task:(TSKTask *)task didFailWithError:(nullable NSError *)error NS_SWIFT_NAME(workflow(_:task:didFailWith:));

/*!
 @abstract Sent to the delegate when one of a workflow’s tasks is cancelled.
 @discussion This is invoked after the task’s delegate receives ‑taskDidCancel:.
 @param workflow The workflow that contains the task.
 @param task The task that was cancelled.
 */
- (void)workflow:(TSKWorkflow *)workflow taskDidCancel:(TSKTask *)task;

@end

NS_ASSUME_NONNULL_END
