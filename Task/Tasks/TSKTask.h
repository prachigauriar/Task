//
//  TSKTask.h
//  Task
//
//  Created by Prachi Gauriar on 10/11/2014.
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

#import <Foundation/Foundation.h>


#pragma mark Constants and Functions

/*! TSKTaskState enumerates the various states that a TSKTask can be in. */
typedef NS_ENUM(NSUInteger, TSKTaskState) {
    /*! State indicating that the task’s prerequisites have not yet finished successfully. */
    TSKTaskStatePending,

    /*! 
     State indicating that the task’s prerequisites have finished successfully and that the task is
     ready to execute. 
     */
    TSKTaskStateReady,

    /*! State indicating that the task is executing. */
    TSKTaskStateExecuting,

    /*! State indicating that the task was cancelled. */
    TSKTaskStateCancelled,

    /*! State indicating that the task finished successfully. */
    TSKTaskStateFinished,

    /*! State indicating that the task failed. */
    TSKTaskStateFailed
};

/*!
 @abstract Returns a string representation of the specified task state.
 @param state The task state.
 @result A string describing the specified task state. If the task state is unknown, returns nil.
 */
extern NSString *const TSKTaskStateDescription(TSKTaskState state);


/*!
 @abstract Notification posted when a task is cancelled.
 @discussion This notification is posted immediately after the task goes into the cancelled state.
     The object of the notification is the task. It has no userInfo dictionary.
 */
extern NSString *const TSKTaskDidCancelNotification;

/*!
 @abstract Notification posted when a task fails.
 @discussion This notification is posted immediately after the task’s delegate is sent the
     ‑task:didFailWithError: message. The object of the notification is the task. It has no userInfo
     dictionary.
 */
extern NSString *const TSKTaskDidFailNotification;

/*!
 @abstract Notification posted when a task finishes successfully.
 @discussion This notification is posted immediately after the task’s delegate is sent the
     ‑task:didFinishWithResult: message. The object of the notification is the task. It has no
     userInfo dictionary.
 */
extern NSString *const TSKTaskDidFinishNotification;

/*!
 @abstract Notification posted when a task is reset.
 @discussion This notification is posted immediately after the task is reset but before it is
     automatically restarted. The object of the notification is the task. It has no userInfo
     dictionary.
 */
extern NSString *const TSKTaskDidResetNotification;

/*!
 @abstract Notification posted when a task is retried.
 @discussion This notification is posted immediately after the task is put back into the pending
     state. The object of the notification is the task. It has no userInfo dictionary.
 */
extern NSString *const TSKTaskDidRetryNotification;

/*!
 @abstract Notification posted when a task starts.
 @discussion This notification is posted immediately after the task goes into the executing state,
     but before the task’s main method begins executing. The object of the notification is the task.
     It has no userInfo dictionary.
 */
extern NSString *const TSKTaskDidStartNotification;



#pragma mark -

@class TSKWorkflow;
@protocol TSKTaskDelegate;

/*!
 TSKTask objects model units of work that can finish successfully or fail. While similar to
 NSOperations, the additional concepts of success and failure enable a greater range of behavior
 when executing a series of related tasks.

 For tasks to be useful, they must be added to a task workflow — a TSKWorkflow object. Task
 workflows provide an execution context for tasks and keep track of prerequisite and dependent
 relationships between them. While tasks can be started directly (using ‑start), they are more
 typically started by sending their workflow the ‑start message, which begins executing all tasks in
 the workflow that have no prerequisite tasks. When all of a task’s prerequisite tasks have finished
 successfully, the task will automatically be enqueued for execution. A task cannot be executed
 until all of its prerequisite tasks have completed successfully. If a task fails, it can be retried
 using the ‑retry message. See the TSKWorkflow documentation for more information on running tasks.

 To make a task perform useful work, you must subclass TSKTask and override ‑main. Your
 implementation should execute any operations necessary to complete your task, and invoke either
 ‑finishWithResult: or ‑failWithError: when complete. If you want to avoid subclassing, you can also
 use TSKBlockTask and TSKSelectorTask. See their respective class documentation for more information.

 Tasks have two types of prerequisites, keyed and unkeyed, which have a simple distinction: a keyed
 prerequisite has a unique key that can be used to retrieve its result, while an unkeyed prerequisite
 does not. Keyed prerequisites are primarily useful when a task has many prerequisites with different
 kinds of results. If your task ignores its prerequisites’ results, has only one prerequisite, or has
 many prerequisites whose results are treated uniformly, unkeyed prerequisites may be more convenient
 to use. Keyed and unkeyed prerequisites may also be used in combination, though this is rare. Task
 subclasses can declare which prerequisite keys are required by overriding ‑requiredPrerequisiteKeys.

 Every TSKTask has an optional delegate that can be informed when a task succeeds or fails. See the
 documentation for TSKTaskDelegate for more information.
 */
@interface TSKTask : NSObject

/*! 
 @abstract The task’s name. 
 @discussion The default value of this property is “TSKTask «id»”, where «id» is the memory address
     of the task. 
 */
@property (nonatomic, copy) NSString *name;

/*! The task’s delegate. */
@property (nonatomic, weak) id<TSKTaskDelegate> delegate;

/*!
 @abstract The task’s operation queue.
 @discussion If not explicitly set, the task’s queue will be the same as its workflow’s.
 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/*! 
 @abstract The task’s workflow. 
 @discussion This property is set when the task is added to a workflow. Once a task has been added
     to a workflow, it may not be added (or moved) to another workflow.
 */
@property (nonatomic, weak, readonly) TSKWorkflow *workflow;

/*!
 @abstract The task’s prerequisite tasks.
 @discussion This method returns a task’s keyed and unkeyed prerequisite tasks. A task’s prerequisite
     tasks can only be set when the task is added to a workflow via -[TSKWorkflow 
     addTask:prerequisiteTasks:keyedPrerequisites:] or a related method. Until then, this property is
     nil.

     This property is not key-value observable.
 */
@property (nonatomic, copy, readonly) NSSet *prerequisiteTasks;

/*!
 @abstract The task’s keyed prerequisite tasks.
 @discussion A task’s keyed prerequisite tasks can only be set when the task is added to a workflow
     via -[TSKWorkflow addTask:prerequisiteTasks:keyedPrerequisites:] or a related method. Until then,
     this property is nil.

     This property is not key-value observable.
 */
@property (nonatomic, copy, readonly) NSDictionary *keyedPrerequisiteTasks;

/*!
 @abstract The task’s unkeyed prerequisite tasks.
 @discussion A task’s prerequisite tasks can only be set when the task is added to a workflow
     via -[TSKWorkflow addTask:prerequisiteTasks:keyedPrerequisites:] or a related method. Until then,
     this property is nil.

     This property is not key-value observable.
 */
@property (nonatomic, copy, readonly) NSSet *unkeyedPrerequisiteTasks;

/*!
 @abstract The task’s dependent tasks.
 @discussion A task’s dependent tasks can only be affected when a dependent task is added to a
     workflow via -[TSKWorkflow addTask:prerequisiteTasks:keyedPrerequisites:] or a related 
     method. If the task is not in a task workflow, this property is nil.

     This property is not key-value observable.
 */
@property (nonatomic, copy, readonly) NSSet *dependentTasks;

/*!
 @abstract The task’s state.
 @discussion When a task is created, this property is initialized to TSKTaskStateReady. The value
     changes automatically in response to the state of the task’s workflow and its execution state.
 */
@property (nonatomic, assign, readonly) TSKTaskState state;

/*!
 @abstract Whether the task is ready to execute.
 @discussion A task is ready to execute if all of its prerequisite tasks have finished successfully.
 */
@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

/*! 
 @abstract Whether the task is executing. 
 @discussion Subclasses should periodically check this property during the execution of the ‑main
     method and quit executing if it is set to NO.
 */
@property (nonatomic, assign, readonly, getter=isExecuting) BOOL executing;

/*! Whether the task has been cancelled. */
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

/*! Whether the task finished successfully. */
@property (nonatomic, assign, readonly, getter=isFinished) BOOL finished;

/*! Whether the task failed. */
@property (nonatomic, assign, readonly, getter=isFailed) BOOL failed;

/*!
 @abstract The date at which the task either finished successfully or failed. 
 @discussion This is nil until the task receives either ‑finishWithResult: or ‑failWithError:.
 */
@property (nonatomic, strong, readonly) NSDate *finishDate;

/*!
 @abstract The result of the task finishing successfully. 
 @discussion This is nil until the task receives ‑finishWithResult:, after which it is the value
     of that message’s result parameter.
 */
@property (nonatomic, strong, readonly) id result;

/*!
 @abstract The error that caused the task to fail. 
 @discussion This is nil until the task receives ‑failWithError:, after which it is the value of
     that message’s error parameter.
 */
@property (nonatomic, strong, readonly) NSError *error;


#pragma mark -

/*!
 @abstract Initializes a newly created TSKTask instance with the specified name.
 @discussion The task will have an initial state of TSKTaskStateReady and no prerequisite or 
     dependent tasks.
     
     This is the class’s designated initializer.
 @param name The name of the task. If nil, the instance’s name will be set to “TSKTask «id»”, where
     «id» is the memory address of the task.
 @result A newly initialized TSKTask instance with the specified name.
 */
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

/*!
 @abstract Returns the prerequisite keys that the receiver requires to run.
 @discussion Returns an empty set by default. Subclasses can override this method to return a set of
     keys for keyed prerequisites that the task requires. When the task is added to a workflow, the
     workflow will ensure that the task’s required keyed prerequisites are fulfilled. If this property
     is nil, no prerequisite keys are required.
 
     Subclasses that override this method should take care to include their superclass’s required keys
     in the set they return. For example, an appropriate implementation may look like:
 
         - (NSSet *)requiredPrerequisiteKeys
         {
             return [[super requiredPrerequisiteKeys] setByAddingObjectsFromArray:@[ @"a", @"b" ]];
         }

     Since the base implementation fo this class returns the empty set, direct subclasses of TSKTask
     need not do this.
 @result The set of prerequisite keys that the receiver requires to run.
 */
- (NSSet *)requiredPrerequisiteKeys;

/*!
 @abstract Performs the task’s work.
 @discussion The default implementation of this method simply invokes ‑finishWithResult: with a nil
     parameter. You should override this method to perform any work necessary to complete your task.
     In your implementation, do not invoke super. When your work is complete, it is imperative that
     the receiver be sent either ‑finishWithResult: or ‑failWithError:. Failing to do so will
     prevent dependent tasks from executing. When appropriate, you can send the receiver the ‑cancel
     message to abort execution without completion.

     Subclass implementations of this method should periodically check whether the task is in the
     executing state (-isExecuting) and, if not, stop executing at the earliest possible moment.
 */
- (void)main;

/*!
 @abstract Executes the task’s ‑main method if the task is in the ready state.
 @discussion More accurately, if the receiver is in the ready state, it will enqueue an operation on
     its workflow’s operation queue that executes the task’s ‑main method if and only if the task is
     ready when the operation begins executing.

     This method should not be invoked if the task has not yet been added to a workflow. Subclasses
     should not override this method.
 */
- (void)start;

/*!
 @abstract Sets the task’s state to cancelled if it is pending, ready, or executing. 
 @discussion Regardless of the receiver’s state, sends the ‑cancel message to all of the receiver’s
     dependent tasks.
 
     Note that this only marks the task as cancelled. It is up individual subclasses of TSKTask to
     stop executing when a task is marked as cancelled. See the documentation of ‑main for more
     information.
     
     Subclasses should invoke the superclass implementation of this method.
 */
- (void)cancel __attribute__((objc_requires_super));

/*!
 @abstract Sets the task’s state to pending if it is executing, finished, failed, or cancelled.
 @discussion If, after being reset, the receiver’s prerequisite tasks have all finished successfully,
     the receiver is automatically put into the ready state. Regardless of the receiver’s state,
     sends the ‑reset message to all of the receiver’s dependent tasks.

     Subclasses should invoke the superclass implementation of this method.
 */
- (void)reset __attribute__((objc_requires_super));

/*!
 @abstract Sets the task’s state to pending if it is cancelled or failed, and starts the task if its
     prerequisite tasks have all finished successfully.
 @discussion Regardless of the receiver’s state, sends the ‑retry message to all of the receiver’s
     dependent tasks.

     Subclasses should invoke the superclass implementation of this method.
 */
- (void)retry __attribute__((objc_requires_super));

/*!
 @abstract Sets the task’s state to finished and updates its result and finishDate properties.
 @discussion Subclasses should ensure that this message is sent to the task when the task’s work
     finishes successfully.
 
     If the receiver’s delegate implements ‑task:didFinishWithResult:, it is sent that message
     after the task’s state is updated.
 @param result An object that represents the result of performing the task’s work. May be nil.
 */
- (void)finishWithResult:(id)result __attribute__((objc_requires_super));

/*!
 @abstract Sets the task’s state to failed and updates its error and finishDate properties.
 @discussion Subclasses should ensure that this message is sent to the task when the task’s work
     fails. 

     If the receiver’s delegate implements ‑task:didFailWithError:, it is sent that message
     after the task’s state is updated.
 @param error An error containing the reason for why the task failed. May be nil, though this is
     discouraged.
 */
- (void)failWithError:(NSError *)error __attribute__((objc_requires_super));


#pragma mark - Prerequisite Results

/*!
 @abstract Returns the result of one of the receiver’s prerequisite tasks.
 @discussion This is primarily useful if the receiver only has or expects one prerequisite. It
     returns the equivalent of [[self.prerequisiteTasks anyObject] result]. No guarantee is made
     that this method will return the same task’s result on repeated invocations.
 @result The result of one of the receiver’s prerequisite tasks.
 */
- (id)anyPrerequisiteResult;

/*!
 @abstract Returns the results of all the receiver’s prerequisite tasks in an array.
 @discussion This is primarily useful if the receiver has many prerequisites that all produce the
     same type of result and processes them uniformly. The returned array will contain NSNull 
     elements for each task that returns nil. The order of the array is arbitrary.
 @result An array containing the results of all the receiver’s prerequisite tasks.
 */
- (NSArray *)allPrerequisiteResults;

/*!
 @abstract Returns the results of all the receiver’s unkeyed prerequisite tasks in an array.
 @discussion The returned array will contain NSNull elements for each task that returns nil. 
     The order of the array is arbitrary.
 @result An array containing the results of all the receiver’s unkeyed prerequisite tasks.
 */
- (NSArray *)allUnkeyedPrerequisiteResults;

/*!
 @abstract Returns the results of all the receiver’s keyed prerequisite tasks in a dictionary.
 @discussion The returned dictionary maps the prerequisite’s key to its result and will contain
     NSNull elements for each task that returns nil.
 @result A dictionary containing the results of all the receiver’s keyed prerequisite tasks.
 */
- (NSDictionary *)keyedPrerequisiteResults;

/*!
 @abstract Returns the result of the prerequisite in the receiver’s keyed prerequisites that has
     the specified key.
 @param prerequisiteKey The key of the prerequisite task whose result is being retrieved.
 @result The result for the receiver’s prerequisite task with the specified key. Returns nil if
     the receiver has no such prerequisite task or the task has a nil result.
 */
- (id)prerequisiteResultForKey:(id<NSCopying>)prerequisiteKey;

/*!
 @abstract Returns the results of all the receiver’s prerequisite tasks in a map table.
 @discussion The keys in the map table are the prerequisite tasks; the values are their
     corresponding results. The map table will contain NSNull values for each nil result.
 @result A map table containing the results of all the receiver’s prerequisite tasks.
 */
- (NSMapTable *)prerequisiteResultsByTask;

@end


#pragma mark -

/*!
 The SubclassInterface contains methods for use by TSKTask subclasses. These methods should never be
 invoked directly.
 */
@interface TSKTask (SubclassInterface)

/*!
 @abstract Performs actions once the receiver has been cancelled.
 @discussion This method is invoked after the receiver has been put in the cancelled state but
     before it has informed its delegate or posted any relevant notifications. The default
     implementation does nothing. Subclasses can override this method to perform any special actions
     upon cancellation. This method should not be invoked directly.
 */
- (void)didCancel;

/*!
 @abstract Performs actions once the receiver has been reset.
 @discussion This method is invoked after the receiver has been put in the pending state but before
     it has informed its delegate or posted any relevant notifications. The default implementation
     does nothing. Subclasses can override this method to perform any special actions upon being
     reset. This method should not be invoked directly.
 */
- (void)didReset;

/*!
 @abstract Performs actions once the receiver has been retried.
 @discussion This method is invoked after the receiver has been put in the pending state but before
     it has informed its delegate or posted any relevant notifications. The default implementation
     does nothing. Subclasses can override this method to perform any special actions upon being
     retried. This method should not be invoked directly.
 */
- (void)didRetry;

/*!
 @abstract Performs actions once the receiver finishes.
 @discussion This method is invoked after the receiver has been put in the finished state but before
     it has informed its delegate or posted any relevant notifications. The default implementation
     does nothing. Subclasses can override this method to perform any special actions upon finishing.
     This method should not be invoked directly.
 */
- (void)didFinishWithResult:(id)result;

/*!
 @abstract Performs actions once the receiver has failed.
 @discussion This method is invoked after the receiver has been put in the failed state but before
     it has informed its delegate or posted any relevant notifications. The default implementation
     does nothing. Subclasses can override this method to perform any special actions upon failing.
     This method should not be invoked directly.
 */
- (void)didFailWithError:(NSError *)error;

@end


#pragma mark - Task Delegate Protocol

/*!
 The TSKTaskDelegate protocol defines an interface via which a task’s delegate can perform 
 specialized actions when the task finishes successfully or fails.
 */
@protocol TSKTaskDelegate <NSObject>

@optional

/*!
 @abstract Sent to the delegate when the specified task finishes successfully.
 @param task The task that finished.
 @param result An object that represents the result of performing the task’s work. May be nil.
 */
- (void)task:(TSKTask *)task didFinishWithResult:(id)result;

/*!
 @abstract Sent to the delegate when the specified task fails.
 @param task The task that failed.
 @param error An error containing the reason the task failed. May be nil. 
 */
- (void)task:(TSKTask *)task didFailWithError:(NSError *)error;

/*!
 @abstract Sent to the delegate when the specified task is cancelled.
 @param task The task that was cancelled.
 */
- (void)taskDidCancel:(TSKTask *)task;

@end
