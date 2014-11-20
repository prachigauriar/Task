//
//  TSKGraph.m
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

#import <Task/TSKGraph.h>

#import <Task/TSKTask+GraphInterface.h>


@interface TSKGraph ()

/*!
 @abstract The set of tasks in the graph.
 @discussion Access to this object is not thread-safe. This shouldn’t be a problem, as typically a
     graph’s tasks are created and added to the graph and then the graph is started.
 */
@property (nonatomic, strong, readonly) NSMutableSet *tasks;

@property (nonatomic, strong, readonly) dispatch_queue_t finishedTasksQueue;

/*!
 @abstract The set of tasks in the graph that have finished successfully.
 @discussion Access to this object is not thread-safe. All accesses to the set should be synchronized
     on the set itself to maintain data integrity.
 */
@property (nonatomic, strong, readonly) NSMutableSet *finishedTasks;

/*!
 @abstract A map table that maps a task to its prerequisite tasks.
 @discussion The keys for this map table are TSKTask instances and their values are NSSets.
 */
@property (nonatomic, strong, readonly) NSMapTable *prerequisiteTasks;

/*!
 @abstract A map table that maps a task to its dependent tasks.
 @discussion The keys for this map table are TSKTask instances and their values are NSSets. We
     use immutable sets instead of mutable ones because tasks are added to a graph far less
     frequently than a task gets its set of dependent tasks. Repeatedly copying a mutable set
     is probably going to be more expensive than generated a new immutable set every time a
     task gains a new dependent.
 */
@property (nonatomic, strong, readonly) NSMapTable *dependentTasks;

/*! The set of tasks currently in the receiver that have no prerequisite tasks. */
@property (nonatomic, copy, readwrite) NSSet *tasksWithNoPrerequisiteTasks;

/*! The set of tasks currently in the receiver that have no dependent tasks. */
@property (nonatomic, copy, readwrite) NSSet *tasksWithNoDependentTasks;

@end


#pragma mark -

@implementation TSKGraph

- (instancetype)init
{
    return [self initWithName:nil operationQueue:nil];
}


- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name operationQueue:nil];
}


- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue
{
    return [self initWithName:nil operationQueue:operationQueue];
}


- (instancetype)initWithName:(NSString *)name operationQueue:(NSOperationQueue *)operationQueue
{
    self = [super init];
    if (self) {
        // If no name was provided, use the default
        if (!name) {
            name = [[NSString alloc] initWithFormat:@"TSKGraph %p", self];
        }

        // If no operation queue was provided, create one
        if (!operationQueue) {
            operationQueue = [[NSOperationQueue alloc] init];
            operationQueue.name = [[NSString alloc] initWithFormat:@"com.twotoasters.TSKGraph.%@", name];
        }

        _name = [name copy];
        _operationQueue = operationQueue;
        _tasks = [[NSMutableSet alloc] init];
        _finishedTasks = [[NSMutableSet alloc] init];

        NSString *finishedTasksQueueName = [NSString stringWithFormat:@"com.twotoasters.TSKGraph.%@.finishedTasks", _name];
        _finishedTasksQueue = dispatch_queue_create([finishedTasksQueueName UTF8String], DISPATCH_QUEUE_CONCURRENT);

        _prerequisiteTasks = [NSMapTable strongToStrongObjectsMapTable];
        _dependentTasks = [NSMapTable strongToStrongObjectsMapTable];
    }

    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p name = %@>", self.class, self, self.name];
}


- (NSString *)debugDescription
{
    NSMutableArray *descriptions = [[NSMutableArray alloc] initWithObjects:[self description], nil];
    for (TSKTask *task in self.tasksWithNoPrerequisiteTasks) {
        [descriptions addObject:[task recursiveDescriptionWithDepth:1]];
    }

    return [descriptions componentsJoinedByString:@"\n"];
}


- (NSSet *)allTasks
{
    return [self.tasks copy];
}


#pragma mark -

- (void)addTask:(TSKTask *)task prerequisiteTasks:(NSSet *)prerequisiteTasks
{
    NSParameterAssert(task);
    NSAssert(!task.graph, @"Task (%@) has been previously added to a graph (%@)", task, task.graph);

    prerequisiteTasks = prerequisiteTasks ? [prerequisiteTasks copy] : [[NSSet alloc] init];
    NSAssert([prerequisiteTasks isSubsetOfSet:self.tasks], @"Prerequisite tasks have not been added to graph");

    task.graph = self;
    [self.tasks addObject:task];
    [self.prerequisiteTasks setObject:prerequisiteTasks forKey:task];
    [self.dependentTasks setObject:[[NSSet alloc] init] forKey:task];

    for (TSKTask *prerequisiteTask in prerequisiteTasks) {
        NSSet *dependentTasks = [self dependentTasksForTask:prerequisiteTask];

        // We create an immutable set here, because -[TSKTask dependentTasks] just invokes
        // -[TSKGraph dependentTasksForTask:], which would need to return a copy of the set if
        // we stored mutable sets. Since -[TSKTask dependentTasks] is likely to be invoked many more
        // times than this method, and creating copies of mutable sets is not cheap, we’re better of
        // using immutable sets.
        [self.dependentTasks setObject:[dependentTasks setByAddingObject:task] forKey:prerequisiteTask];
    }

    if (prerequisiteTasks.count != 0) {
        [task didAddPrerequisiteTask];
    }

    self.tasksWithNoPrerequisiteTasks = [self.tasks objectsPassingTest:^BOOL(TSKTask *task, BOOL *stop) {
        return task.prerequisiteTasks.count == 0;
    }];

    self.tasksWithNoDependentTasks = [self.tasks objectsPassingTest:^BOOL(TSKTask *task, BOOL *stop) {
        return task.dependentTasks.count == 0;
    }];
}


- (void)addTask:(TSKTask *)task prerequisites:(TSKTask *)prerequisiteTask1, ...
{
    va_list argList;
    va_start(argList, prerequisiteTask1);

    NSMutableSet *prerequisiteTasks = [[NSMutableSet alloc] init];
    TSKTask *prerequisiteTask = prerequisiteTask1;
    while (prerequisiteTask) {
        [prerequisiteTasks addObject:prerequisiteTask];
        prerequisiteTask = va_arg(argList, TSKTask *);
    }

    va_end(argList);

    [self addTask:task prerequisiteTasks:prerequisiteTasks];
}


- (NSSet *)prerequisiteTasksForTask:(TSKTask *)task
{
    return [self.prerequisiteTasks objectForKey:task];
}


- (NSSet *)dependentTasksForTask:(TSKTask *)task
{
    return [self.dependentTasks objectForKey:task];
}


- (BOOL)hasUnfinishedTasks
{
    __block BOOL hasUnfinishedTasks = NO;
    dispatch_sync(self.finishedTasksQueue, ^{
        hasUnfinishedTasks = ![self.tasksWithNoDependentTasks isSubsetOfSet:self.finishedTasks];
    });

    return hasUnfinishedTasks;
}


- (BOOL)hasFailedTasks
{
    for (TSKTask *task in self.tasks) {
        if (task.isFailed) {
            return YES;
        }
    }

    return NO;
}


#pragma mark -

- (void)start
{
    [self.tasksWithNoPrerequisiteTasks makeObjectsPerformSelector:@selector(start)];
}


- (void)cancel
{
    [self.tasksWithNoPrerequisiteTasks makeObjectsPerformSelector:@selector(cancel)];
}


- (void)retry
{
    [self.tasksWithNoPrerequisiteTasks makeObjectsPerformSelector:@selector(retry)];
}


#pragma mark - Subtask State

- (void)subtask:(TSKTask *)task didFinishWithResult:(id)result
{
    dispatch_barrier_async(self.finishedTasksQueue, ^{
        [self.finishedTasks addObject:task];
    });

    if ([self.delegate respondsToSelector:@selector(graphDidFinish:)] && ![self hasUnfinishedTasks]) {
        [self.delegate graphDidFinish:self];
    }
}


- (void)subtask:(TSKTask *)task didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(graph:task:didFailWithError:)]) {
        [self.delegate graph:self task:task didFailWithError:error];
    }
}


- (void)subtaskDidReset:(TSKTask *)task
{
    dispatch_barrier_async(self.finishedTasksQueue, ^{
        [self.finishedTasks removeObject:task];
    });
}

@end
