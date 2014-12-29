//
//  TSKTask.m
//  Task
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

#import <Task/TSKTask.h>

#import <Task/TSKWorkflow.h>
#import <Task/TSKWorkflow+TaskInterface.h>
#import <Task/TSKTask+WorkflowInterface.h>


#pragma mark Constants and Functions

NSString *const TSKTaskDidCancelNotification = @"TSKTaskDidCancelNotification";
NSString *const TSKTaskDidFailNotification = @"TSKTaskDidFailNotification";
NSString *const TSKTaskDidFinishNotification = @"TSKTaskDidFinishNotification";
NSString *const TSKTaskDidResetNotification = @"TSKTaskDidResetNotification";
NSString *const TSKTaskDidRetryNotification = @"TSKTaskDidRetryNotification";
NSString *const TSKTaskDidStartNotification = @"TSKTaskDidStartNotification";


NSString *const TSKTaskStateDescription(TSKTaskState state)
{
    switch (state) {
        case TSKTaskStatePending:
            return @"Pending";
        case TSKTaskStateReady:
            return @"Ready";
        case TSKTaskStateExecuting:
            return @"Executing";
        case TSKTaskStateCancelled:
            return @"Cancelled";
        case TSKTaskStateFinished:
            return @"Finished";
        case TSKTaskStateFailed:
            return @"Failed";
        default:
            return nil;
    }
}


#pragma mark -

@interface TSKTask ()

@property (nonatomic, weak, readwrite) TSKWorkflow *workflow;

@property (nonatomic, strong, readwrite) NSDate *finishDate;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) id result;

/*!
 @abstract A dispatch queue to control changes to task state.
 @discussion This queue is only used within ‑transitionFromStateInSet:toState:andExecuteBlock: to 
     perform data synchronization.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t stateQueue;

/*!
 @abstract If the receiver’s state is in the specified set of from-states, transitions to the specified
     to-state and executes the block.
 @param validFromStates The set of states from which the receiver can transition.
 @param toState The state to which the receiver will transition.
 @param block A block of code to execute after the state transition is completed successfully.
 */
- (void)transitionFromStateInSet:(NSSet *)validFromStates toState:(TSKTaskState)toState andExecuteBlock:(void (^)(void))block;

/*!
 @abstract If the receiver’s state is the specified from-state, transitions to the specified to-state 
     and executes the block.
 @param fromState The state from which the receiver can transition.
 @param toState The state to which the receiver will transition.
 @param block A block of code to execute after the state transition is completed successfully.
 */
- (void)transitionFromState:(TSKTaskState)fromState toState:(TSKTaskState)toState andExecuteBlock:(void (^)(void))block;

/*!
 @abstract Returns whether all the receiver’s prerequisite tasks have finished successfully.
 @result Whether all the receiver’s prerequisite tasks have finished successfully.
 */
- (BOOL)allPrerequisiteTasksFinished;

/*!
 @abstract If all the receiver’s prerequisite tasks have finished successfully, transitions from
     pending to ready and executes the specified block.
 */
- (void)transitionToReadyStateAndExecuteBlock:(void (^)(void))block;

/*!
 @abstract If all the receiver’s prerequisite tasks have finished successfully, transitions from 
     pending to ready and starts the task.
 */
- (void)startIfReady;

@end


#pragma mark -

@implementation TSKTask

- (instancetype)init
{
    return [self initWithName:nil];
}


- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        if (!name) {
            name = [[NSString alloc] initWithFormat:@"TSKTask %p", self];
        }

        _name = [name copy];
        _state = TSKTaskStateReady;
        NSString *stateQueueName = [NSString stringWithFormat:@"com.twotoasters.TSKTask.%@.state", name];
        _stateQueue = dispatch_queue_create([stateQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p name = %@; state = %@>", self.class, self, self.name, TSKTaskStateDescription(self.state)];
}


- (NSString *)debugDescription
{
    return [self recursiveDescriptionWithDepth:0];
}


- (NSString *)prefixedDescriptionWithDepth:(NSUInteger)depth
{
    static NSString *const kPrefix = @"   | ";

    NSMutableString *prefixString = [[NSMutableString alloc] initWithCapacity:depth * kPrefix.length];
    for (NSUInteger i = 0; i < depth; ++i) {
        [prefixString appendString:kPrefix];
    }

    return [prefixString stringByAppendingString:[self description]];
}


- (NSString *)recursiveDescriptionWithDepth:(NSUInteger)depth
{
    NSMutableArray *descriptions = [[NSMutableArray alloc] initWithObjects:[self prefixedDescriptionWithDepth:depth], nil];

    for (TSKTask *task in self.dependentTasks) {
        [descriptions addObject:[task recursiveDescriptionWithDepth:depth + 1]];
    }

    return [descriptions componentsJoinedByString:@"\n"];
}


- (NSSet *)prerequisiteTasks
{
    return [self.workflow prerequisiteTasksForTask:self];
}


- (NSSet *)dependentTasks
{
    return [self.workflow dependentTasksForTask:self];
}


- (NSOperationQueue *)operationQueue
{
    return _operationQueue ? _operationQueue : self.workflow.operationQueue;
}


#pragma mark - States

+ (BOOL)automaticallyNotifiesObserversOfState
{
    // This avoids a deadlock condition in ‑transitionFromStateInSet:toState:andExecuteBlock: in which
    // the stateQueue is in use, but KVO observers are notified of the change before the state transition
    // block exits the queue. This is a problem when, e.g., upon task failure, a KVO observer is notified
    // on the same thread as the aforementioned method. If the KVO observer immediately sends the task
    // ‑retry, that message will result in ‑transitionFromStateInSet:toState:andExecuteBlock: being
    // invoked again before the block from the original invocation exits the stateQueue, thus resulting
    // in deadlock.
    return NO;
}


+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    static NSSet *stateKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stateKeys = [NSSet setWithObjects:@"ready", @"executing", @"cancelled", @"finished", @"failed", nil];
    });

    return [stateKeys containsObject:key] ? [NSSet setWithObject:@"state"] : [super keyPathsForValuesAffectingValueForKey:key];
}


- (BOOL)isReady
{
    return self.state == TSKTaskStateReady;
}


- (BOOL)isExecuting
{
    return self.state == TSKTaskStateExecuting;
}


- (BOOL)isCancelled
{
    return self.state == TSKTaskStateCancelled;
}


- (BOOL)isFinished
{
    return self.state == TSKTaskStateFinished;
}


- (BOOL)isFailed
{
    return self.state == TSKTaskStateFailed;
}


- (void)transitionFromStateInSet:(NSSet *)validFromStates toState:(TSKTaskState)toState andExecuteBlock:(void (^)(void))block
{
    NSParameterAssert(validFromStates);

    // State transitions:
    //     Pending -> Ready: All of task’s prerequisite tasks are finished (-transitionToReadyStateAndExecuteBlock:)
    //     Pending -> Cancelled: Task is cancelled (-cancel)
    //
    //     Ready -> Pending: Task is added to a workflow with at least one prerequisite task (-didAddPrerequisiteTask)
    //     Ready -> Executing: Task starts (-start)
    //     Ready -> Cancelled: Task is cancelled (-cancel)
    //
    //     Executing -> Pending: Task is reset (-reset)
    //     Executing -> Cancelled: Task is cancelled (-cancel)
    //     Executing -> Finished: Task finishes (-finishWithResult:)
    //     Executing -> Failed: Task fails (-failWithError:)
    //
    //     Cancelled -> Pending: Task is retried (-retry) or reset (-reset)
    //
    //     Finished -> Pending: Task is reset (-reset)
    //
    //     Failed -> Pending: Task is retried (-retry) or reset (-reset)

    __block BOOL didTransition = NO;
    dispatch_sync(self.stateQueue, ^{
        // If the current state is not in the set of valid from-states, we have nothing to do
        if (![validFromStates containsObject:@(self.state)]) {
            return;
        }

        // Otherwise, if the from-state and the to-state differ, change the state. We should avoid triggering
        // KVO notifications. See the explanatory comments in +automaticallyNotifiesObserversOfState.
        TSKTaskState fromState = self.state;
        if (fromState != toState) {
            [self willChangeValueForKey:@"state"];
            _state = toState;
            didTransition = YES;
        }
    });

    if (didTransition) {
        [self didChangeValueForKey:@"state"];

        // Only once all KVO notifications have fired should we execute the block
        if (block) {
            block();
        }
    }
}


- (void)transitionFromState:(TSKTaskState)fromState toState:(TSKTaskState)toState andExecuteBlock:(void (^)(void))block
{
    [self transitionFromStateInSet:[NSSet setWithObject:@(fromState)] toState:toState andExecuteBlock:block];
}


- (void)didAddPrerequisiteTask
{
    if (![self allPrerequisiteTasksFinished]) {
        [self transitionFromState:TSKTaskStateReady toState:TSKTaskStatePending andExecuteBlock:nil];
    }
}


#pragma mark - Execution

- (void)main
{
    [self finishWithResult:nil];
}


- (void)start
{
    NSAssert(self.workflow, @"Tasks must be in a workflow before they can be started");

    if (!self.isReady) {
        return;
    }

    // Because the operation queue is asynchronous, we need to be sure to do the state transition
    // after the operation starts executing. The alternative of adding the operation inside of the
    // state transition’s block could lead to a weird situation in which ‑main is invoked, but the
    // task has already been marked cancelled. This shouldn’t be an issue, since ‑main should be
    // checking if the task is cancelled and exiting as soon as possible, but that’s not always
    // possible. Doing the check inside the operation’s block before invoking ‑main avoids that.
    [self.operationQueue addOperationWithBlock:^{
        [self transitionFromState:TSKTaskStateReady toState:TSKTaskStateExecuting andExecuteBlock:^{
            [self.workflow.notificationCenter postNotificationName:TSKTaskDidStartNotification object:self];
            [self main];
        }];
    }];
}


- (BOOL)allPrerequisiteTasksFinished
{
    for (TSKTask *task in self.prerequisiteTasks) {
        if (!task.isFinished) {
            return NO;
        }
    }

    return YES;
}


- (void)transitionToReadyStateAndExecuteBlock:(void (^)(void))block
{
    if ([self allPrerequisiteTasksFinished]) {
        [self transitionFromState:TSKTaskStatePending toState:TSKTaskStateReady andExecuteBlock:block];
    }
}


- (void)startIfReady
{
    [self transitionToReadyStateAndExecuteBlock:^{
        [self start];
    }];
}


- (void)cancel
{
    static NSSet *fromStates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fromStates = [[NSSet alloc] initWithObjects:@(TSKTaskStatePending), @(TSKTaskStateReady), @(TSKTaskStateExecuting), nil];
    });

    [self transitionFromStateInSet:fromStates toState:TSKTaskStateCancelled andExecuteBlock:^{
        if ([self.delegate respondsToSelector:@selector(taskDidCancel:)]) {
            [self.delegate taskDidCancel:self];
        }

        [self.workflow.notificationCenter postNotificationName:TSKTaskDidCancelNotification object:self];
        [self.workflow subtaskDidCancel:self];
    }];
    
    [self.dependentTasks makeObjectsPerformSelector:@selector(cancel)];
}


- (void)reset
{
    static NSSet *fromStates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fromStates = [[NSSet alloc] initWithObjects:@(TSKTaskStateExecuting), @(TSKTaskStateFinished), @(TSKTaskStateFailed), @(TSKTaskStateCancelled), nil];
    });

    [self transitionFromStateInSet:fromStates toState:TSKTaskStatePending andExecuteBlock:^{
        self.finishDate = nil;
        self.result = nil;
        self.error = nil;
        [self.workflow subtaskDidReset:self];
        [self.workflow.notificationCenter postNotificationName:TSKTaskDidResetNotification object:self];
        [self transitionToReadyStateAndExecuteBlock:nil];
    }];

    [self.dependentTasks makeObjectsPerformSelector:@selector(reset)];
}


- (void)retry
{
    static NSSet *fromStates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fromStates = [[NSSet alloc] initWithObjects:@(TSKTaskStateCancelled), @(TSKTaskStateFailed), nil];
    });

    [self transitionFromStateInSet:fromStates toState:TSKTaskStatePending andExecuteBlock:^{
        self.finishDate = nil;
        self.result = nil;
        self.error = nil;
        [self.workflow.notificationCenter postNotificationName:TSKTaskDidRetryNotification object:self];
        [self startIfReady];
    }];

    [self.dependentTasks makeObjectsPerformSelector:@selector(retry)];
}


- (void)finishWithResult:(id)result
{
    [self transitionFromState:TSKTaskStateExecuting toState:TSKTaskStateFinished andExecuteBlock:^{
        self.finishDate = [NSDate date];
        self.result = result;

        if ([self.delegate respondsToSelector:@selector(task:didFinishWithResult:)]) {
            [self.delegate task:self didFinishWithResult:result];
        }

        [self.workflow.notificationCenter postNotificationName:TSKTaskDidFinishNotification object:self];
        [self.workflow subtask:self didFinishWithResult:result];
        [self.dependentTasks makeObjectsPerformSelector:@selector(startIfReady)];
    }];
}


- (void)failWithError:(NSError *)error
{
    [self transitionFromState:TSKTaskStateExecuting toState:TSKTaskStateFailed andExecuteBlock:^{
        self.finishDate = [NSDate date];
        self.error = error;

        if ([self.delegate respondsToSelector:@selector(task:didFailWithError:)]) {
            [self.delegate task:self didFailWithError:error];
        }

        [self.workflow.notificationCenter postNotificationName:TSKTaskDidFailNotification object:self];
        [self.workflow subtask:self didFailWithError:error];
    }];
}

@end
