//
//  TSKGraph.h
//  Task
//
//  Created by Prachi Gauriar on 10/14/2014.
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

#import <Foundation/Foundation.h>


#pragma mark Constants

/*!
 @abstract Notification posted when all a graph’s tasks finished.
 @discussion This notification is posted immediately after the graph’s delegate is sent the
     ‑graphDidFinish: message. The object of the notification is the graph. It has no userInfo
     dictionary.
 */
extern NSString *const TSKGraphDidFinishNotification;

/*!
 @abstract Notification posted when all a graph’s tasks finished.
 @discussion This notification is posted immediately after the graph’s delegate is sent the
     ‑graph:task:didFailWithError: message. The object of the notification is the graph. Its
     userInfo dictionary contains a single key, TSKGraphFailedTaskKey, whose value is the task that
     failed.
 */
extern NSString *const TSKGraphTaskDidFailNotification;

/*!
 @abstract Notification posted when a graph is about to cancel its tasks.
 @discussion This notification is posted immediately before the graph’s tasks are sent the ‑cancel
     message. The object of the notification is the graph. It has no userInfo dictionary.
 */
extern NSString *const TSKGraphWillCancelNotification;

/*!
 @abstract Notification posted when a graph about to retry its tasks.
 @discussion This notification is posted immediately before the graph’s tasks are sent the ‑retry
     message. The object of the notification is the graph. It has no userInfo dictionary.
 */
extern NSString *const TSKGraphWillRetryNotification;

/*!
 @abstract Notification posted when a graph is about to start its tasks.
 @discussion This notification is posted immediately before the graph’s tasks are sent the ‑start
     message. The object of the notification is the graph. It has no userInfo dictionary.
 */
extern NSString *const TSKGraphWillStartNotification;

/*!
 @abstract Notification userInfo key whose value is a TSKTask object that failed.
 */
extern NSString *const TSKGraphFailedTaskKey;


#pragma mark -

@class TSKTask;
@protocol TSKGraphDelegate;

/*!
 Instances of TSKGraph, or simply task graphs, provide execution contexts for tasks and keep
 track of prerequisite and dependent relationships between them. Tasks cannot be executed without
 first being added to a graph. Once a task is added to a graph, it cannot be placed in another
 graph.

 Every task graph has an operation queue on which its tasks ‑main methods are enqueued.

 Task graphs also have the ability to be started, canceled, or retried, which simply sends the
 appropriate message to those tasks in the graph that have no prerequisites. At that point, the
 messages will propagate throughout the graph.

 Every TSKGraph has an optional delegate that can be informed when all the graph’s tasks finish
 successfully or any of the tasks fail. See the documentation for TSKGraphDelegate for more 
 information.
*/
@interface TSKGraph : NSObject

/*!
 @abstract The task graph’s name.
 @discussion The default value of this property is “TSKGraph «id»”, where «id» is the memory
     address of the task graph.
 */
@property (nonatomic, copy) NSString *name;

/*! The task graph’s delegate. */
@property (nonatomic, weak) id<TSKGraphDelegate> delegate;

/*!
 @abstract The task graph’s operation queue.
 @discussion If no operation queue is provided upon initialization, a queue will be created for the
     task graph with the default quality of service and maximum concurrent operations count. Its name
     will be of the form “com.twotoasters.TSKGraph.«name»”, where «name» is the name of the task
     graph.
 */
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

/*!
 @abstract The task graph’s notification center.
 @discussion All notifications posted by the graph and its tasks will be posted to this notification
     center. By default, this is the default notification center.
 */
@property (nonatomic, strong, readonly) NSNotificationCenter *notificationCenter;

/*! The task graph’s current set of tasks. */
@property (nonatomic, copy, readonly) NSSet *allTasks;

/*! The set of tasks currently in the receiver that have no prerequisite tasks. */
@property (nonatomic, copy, readonly) NSSet *tasksWithNoPrerequisiteTasks;

/*! The set of tasks currently in the receiver that have no dependent tasks. */
@property (nonatomic, copy, readonly) NSSet *tasksWithNoDependentTasks;

/*!
 @abstract Initializes a newly created TSKGraph instance with the specified name.
 @discussion A new operation queue will be created for the task graph with the default quality of
     service and maximum concurrent operations count. The queue’s name will be of the form
     “com.twotoasters.TSKGraph.«name»”, where «name» is the name of the task graph.
 @param name The name of the task graph. If nil, the instance’s name will be set to 
     “TSKGraph «id»”, where «id» is the memory address of the task.
 @result A newly initialized TSKGraph instance with the specified name.
 */
- (instancetype)initWithName:(NSString *)name;

/*!
 @abstract Initializes a newly created TSKGraph instance with the specified operation queue.
 @discussion The task graph will have a name of “TSKGraph «id»”, where «id» is the memory
     address of the task graph.
 @param operationQueue The operation queue the graph’s tasks will use to execute their ‑main
     methods. If nil, a new operation queue will be created for the task graph with the default
     quality of service and maximum concurrent operations count. The queue’s name will be of the
     form “com.twotoasters.TSKGraph.«name»”, where «name» is the name of the task graph.
 @result A newly initialized TSKGraph instance with the specified operation queue.
 */
- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue;

/*!
 @abstract Initializes a newly created TSKGraph instance with the specified name and operation
     queue.
 @param name The name of the task graph. If nil, the instance’s name will be set to
     “TSKGraph «id»”, where «id» is the memory address of the task.
 @param operationQueue The operation queue the graph’s tasks will use to execute their ‑main
     methods. If nil, a new operation queue will be created for the task graph with the default
     quality of service and maximum concurrent operations count. The queue’s name will be of the
     form “com.twotoasters.TSKGraph.«name»”, where «name» is the name of the task graph.
 @result A newly initialized TSKGraph instance with the specified name and operation queue.
 */
- (instancetype)initWithName:(NSString *)name operationQueue:(NSOperationQueue *)operationQueue;

/*!
 @abstract Initializes a newly created TSKGraph instance with the specified name, operation
     queue, and notification center.
 @discussion This is the class’s designated initializer.
 @param name The name of the task graph. If nil, the instance’s name will be set to
     “TSKGraph «id»”, where «id» is the memory address of the task.
 @param operationQueue The operation queue the graph’s tasks will use to execute their ‑main
     methods. If nil, a new operation queue will be created for the task graph with the default
     quality of service and maximum concurrent operations count. The queue’s name will be of the
     form “com.twotoasters.TSKGraph.«name»”, where «name» is the name of the task graph.
 @param notificationCenter The notification center the graph and its tasks will use to post 
     notifications. If nil, the default notification center will be used.
 @result A newly initialized TSKGraph instance with the specified name, operation queue,
     and notification center.
 */
- (instancetype)initWithName:(NSString *)name
              operationQueue:(NSOperationQueue *)operationQueue
          notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

/*!
 @abstract Adds the specified task to the task graph with the specified set of prerequisite tasks.
 @discussion The task’s graph property is set to the receiver, and its prerequisite tasks are set 
     to the ones specified. Furthermore, the task is added to each of the prerequisite tasks’ sets
     of dependent tasks. If the task has any prerequisites, its state is set to pending.
 
     This is not a thread-safe operation. This method should only execute on one thread at a time.
 @param task The task to add. May not be nil. May not be a member of any other task graph.
 @param prerequisiteTasks The task’s prerequisite tasks. If nil, the task will have no prerequisite
     tasks. Otherwise, each task in the set must have already been added to the receiver.
 */
- (void)addTask:(TSKTask *)task prerequisiteTasks:(NSSet *)prerequisiteTasks;

/*!
 @abstract Adds the specified task to the task graph with the specified list of prerequisite tasks.
 @discussion The task’s graph property is set to the receiver, and its prerequisite tasks are set 
     to the ones specified. Furthermore, the task is added to each of the prerequisite tasks’ sets
     of dependent tasks. If the task has any prerequisites, its state is set to pending.

     This is not a thread-safe operation. This method should only execute on one thread at a time.
 @param task The task to add. May not be nil. May not be a member of any other task graph.
 @param prerequisiteTask1 ... The task’s prerequisite tasks as a nil-terminated list. Each task in
     the set must have already been added to the receiver.
 */
- (void)addTask:(TSKTask *)task prerequisites:(TSKTask *)prerequisiteTask1, ... NS_REQUIRES_NIL_TERMINATION;

/*!
 @abstract Returns the set of prerequisite tasks for the specified task.
 @param task The task.
 @result The set of prerequisite tasks for the specified task. Returns nil if the task is not in the
     receiver.
 */
- (NSSet *)prerequisiteTasksForTask:(TSKTask *)task;

/*!
 @abstract Returns the set of dependent tasks for the specified task.
 @param task The task.
 @result The set of dependent tasks for the specified task. Returns nil if the task is not in the
     receiver.
 */
- (NSSet *)dependentTasksForTask:(TSKTask *)task;

/*!
 @abstract Sends ‑start to every prerequisite-less task in the receiver.
 @discussion This serves to begin execution of the tasks in the receiver. After the initial set of 
     tasks finish successfully, they will automatically invoke ‑start on their dependent tasks and
     so on until all tasks have finished successfully. If no tasks have been added to the graph, 
     this will immediately send ‑graphDidFinish: to the delegate.
 */
- (void)start;

/*!
 @abstract Sends ‑cancel to every prerequisite-less task in the receiver. 
 @discussion This serves to mark all the tasks in the receiver as cancelled. The initial set of 
     tasks will propagate the cancellation to their dependent tasks and so on until all tasks that
     can be cancelled will be.
 */
- (void)cancel;

/*!
 @abstract Sends ‑retry to every prerequisite-less task in the receiver. 
 @discussion This serves to retry all the tasks in the receiver that have failed. The initial set of 
     tasks will propagate the retry to their dependent tasks and so on until all tasks that
     can be retried will be. If no tasks have been added to the graph, this will immediately send
     ‑graphDidFinish: to the delegate.
 */
- (void)retry;

/*!
 @abstract Returns whether the receiver has any unfinished tasks.
 @discussion This is not key-value observable.
 @result Whether the receiver has any unfinished tasks.
 */
- (BOOL)hasUnfinishedTasks;

/*!
 @abstract Returns whether the receiver has any failed tasks.
 @discussion This is not key-value observable.
 @result Whether the receiver has any failed tasks.
 */
- (BOOL)hasFailedTasks;

@end


#pragma mark - Graph Delegate Protocol

/*!
 The TSKGraphDelegate protocol defines an interface via which a graph’s delegate can perform
 specialized actions when all the tasks in a graph finish successfully or if a single task fails.
 */
@protocol TSKGraphDelegate <NSObject>

@optional

/*!
 @abstract Sent to the delegate when all a graph’s tasks finish successfully.
 @discussion This is invoked after individual task delegates receive ‑task:didFinishWithResult:.
 @param graph The graph whose tasks finished.
 */
- (void)graphDidFinish:(TSKGraph *)graph;

/*!
 @abstract Sent to the delegate when one of a graph’s tasks fail.
 @discussion This is invoked after the task’s delegate receives ‑task:didFailWithError:.
 @param graph The graph that contains the task.
 @param task The task that failed.
 @param error An error containing the reason the task failed. May be nil.
 */
- (void)graph:(TSKGraph *)graph task:(TSKTask *)task didFailWithError:(NSError *)error;

@end
