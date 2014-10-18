//
//  TSKTask.h
//  TaskKit
//
//  Created by Prachi Gauriar on 10/11/2014.
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


#pragma mark -

@class TSKGraph;
@protocol TSKTaskDelegate;

/*!
 TSKTask objects model units of work that can finish successfully or fail. While similar to
 NSOperations, the additional concepts of success and failure enable a greater range of behavior 
 when executing a series of related tasks.

 For tasks to be useful, they must be added to a task graph — a TSKGraph object. Task graphs
 provide an execution context for tasks and keep track of prerequisite and dependent relationships
 between them. While tasks can be started directly (using -start), they are more typically started
 by sending their graph the -start message, which begins executing all tasks in the graph that have
 no prerequisite tasks. When all of a task’s prerequisite tasks have finished successfully, the task
 will automatically be enqueued for execution. A task cannot be executed until all of its
 prerequisite tasks have completed successfully. If a task fails, it can be retried using the -retry
 message. See the TSKGraph documentation for more information on running tasks.
 
 To make a task perform useful work, you must subclass TSKTask and override -main. Your implementation
 should execute any operations necessary to complete your task, and invoke either -finishWithResult: or
 -failWithError: when complete. TSKTask has three built-in subclasses — TSKBlockTask, TSKSelectorTask, 
 and TSKExternalConditionTask — which can generally be used as an alternative to subclassing TSKTask 
 yourself. See their respective class documentation for more information.
 
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
 @abstract The task’s graph. 
 @discussion This property is set when the task is added to a graph. Once a task has been added to a
     graph, it may not be added (or moved) to another graph.
 */
@property (nonatomic, weak, readonly) TSKGraph *graph;

/*!
 @abstract The task’s prerequisite tasks.
 @discussion A task’s prerequisite tasks can only be set when the task is added to a graph via
     -[TSKGraph addTask:prerequisiteTasks:] or -[TSKGraph addTask:prerequisites:]. Until
     then, this property is nil.
     
     This property is not key-value observable.
 */
@property (nonatomic, copy, readonly) NSSet *prerequisiteTasks;

/*!
 @abstract The task’s dependent tasks.
 @discussion A task’s dependent tasks can only be affected when a dependent task is added to a
     graph via -[TSKGraph addTask:prerequisiteTasks:] or -[TSKGraph addTask:prerequisites:].
     If the task is not in a task graph, this property is nil.

     This property is not key-value observable.
 */
@property (nonatomic, copy, readonly) NSSet *dependentTasks;

/*!
 @abstract The task’s state.
 @discussion When a task is created, this property is initialized to TSKTaskStateReady. The value
     changes automatically in response to the state of the task’s graph and its execution state.
 */
@property (nonatomic, assign, readonly) TSKTaskState state;

/*!
 @abstract Whether the task is ready to execute.
 @discussion A task is ready to execute if all of its prerequisite tasks have finished successfully.
 */
@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

/*! Whether the task is executing. */
@property (nonatomic, assign, readonly, getter=isExecuting) BOOL executing;

/*!
 @abstract Whether the task has been cancelled.
 @discussion Subclasses should periodically check this property during the execution of the -main
     method and quit executing if it is set to YES.
 */
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

/*! Whether the task finished successfully. */
@property (nonatomic, assign, readonly, getter=isFinished) BOOL finished;

/*! Whether the task failed. */
@property (nonatomic, assign, readonly, getter=isFailed) BOOL failed;

/*!
 @abstract The date at which the task either finished successfully or failed. 
 @discussion This is nil until the task receives either -finishWithResult: or -failWithError:.
 */
@property (nonatomic, strong, readonly) NSDate *finishDate;

/*!
 @abstract The result of the task finishing successfully. 
 @discussion This is nil until the task receives -finishWithResult:, after which it is the value
     of that message’s result parameter.
 */
@property (nonatomic, strong, readonly) id result;

/*!
 @abstract The error that caused the task to fail. 
 @discussion This is nil until the task receives -failWithError:, after which it is the value of
     that message’s error parameter.
 */
@property (nonatomic, strong, readonly) NSError *error;

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
 @abstract Performs the task’s work.
 @discussion The default implementation of this method simply invokes -finishWithResult: with a nil
     parameter. You should override this method to perform any work necessary to complete your task. 
     In your implementation, do not invoke super. When your work is complete, it is imperative that 
     the receiver be sent either -finishWithResult: or -failWithError:. Failing to do so will 
     prevent dependent tasks from executing.
     
     Subclass implementations of this method should periodically check whether the task has been 
     marked as cancelled and, if so, stop executing at the earliest possible moment.
 */
- (void)main;

/*!
 @abstract Executes the task’s -main method if the task is in the ready state.
 @discussion More accurately, the receiver will enqueue an operation on its graph’s operation queue
     that executes the task’s -main method if and only if the task is ready when the operation is 
     executed.
     
     This method should not be invoked if the task has not yet been added to a graph. Subclasses 
     should not override this method.
 */
- (void)start;

/*!
 @abstract Sets the task’s state to cancelled if it is pending, ready, or executing. 
 @discussion Regardless of the receiver’s state, sends the -cancel message to all of the
     receiver’s dependent tasks.
 
     Note that this only marks the task as cancelled. It is up individual subclasses of TSKTask to
     stop executing when a task is marked as cancelled. See the documentation of -main for more
     information.
     
     Subclasses should not override this method.
 */
- (void)cancel;

/*!
 @abstract Sets the task’s state to pending if it is pending, ready, cancelled or failed, and
     starts the task if its prerequisite tasks have all finished successfully.
 @discussion Regardless of the receiver’s state, sends the -retry message to all of the receiver’s
     dependent tasks.

     Subclasses should not override this method.
 */
- (void)retry;

/*!
 @abstract Sets the task’s state to finished and updates its result and finishDate properties.
 @discussion Subclasses should ensure that this message is sent to the task when the task’s work
     finishes successfully.
 
     If the receiver’s delegate implements -task:didFinishWithResult:, it is sent that message
     after the task’s state is updated.
 @param result An object that represents the result of performing the task’s work. May be nil.
 */
- (void)finishWithResult:(id)result;

/*!
 @abstract Sets the task’s state to failed and updates its error and finishDate properties.
 @discussion Subclasses should ensure that this message is sent to the task when the task’s work
     fails. 

     If the receiver’s delegate implements -task:didFinishWithResult:, it is sent that message
     after the task’s state is updated.
 @param error An error containing the reason for why the task failed. May be nil, though this is
     discouraged.
 */
- (void)failWithError:(NSError *)error;

@end


#pragma mark - Task Delegate Protocol

/*!
 The TSKTaskDelegate protocol defines an interface via which an task’s delegate can perform 
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
 @param error An error containing the reason for why the task failed. May be nil. 
 */
- (void)task:(TSKTask *)task didFailWithError:(NSError *)error;

@end