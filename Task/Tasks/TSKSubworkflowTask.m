//
//  TSKSubworkflowTask.m
//  Task
//
//  Created by Prachi Gauriar on 12/27/2014.
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

#import <Task/TSKSubworkflowTask.h>

#import <Task/TSKWorkflow.h>


@implementation TSKSubworkflowTask

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name subworkflow:nil];
}


- (instancetype)initWithSubworkflow:(TSKWorkflow *)subworkflow
{
    return [self initWithName:nil subworkflow:subworkflow];
}


- (instancetype)initWithName:(NSString *)name subworkflow:(TSKWorkflow *)subworkflow
{
    NSParameterAssert(subworkflow);

    self = [super initWithName:name];
    if (self) {
        _subworkflow = subworkflow;

        [subworkflow.notificationCenter addObserver:self
                                           selector:@selector(subworkflowDidFinish:)
                                               name:TSKWorkflowDidFinishNotification
                                             object:subworkflow];
        [subworkflow.notificationCenter addObserver:self
                                           selector:@selector(subworkflowTaskDidCancel:)
                                               name:TSKWorkflowTaskDidCancelNotification
                                             object:subworkflow];
        [subworkflow.notificationCenter addObserver:self
                                           selector:@selector(subworkflowTaskDidFail:)
                                               name:TSKWorkflowTaskDidFailNotification
                                             object:subworkflow];
    }

    return self;
}


- (void)dealloc
{
    [self.subworkflow.notificationCenter removeObserver:self];
}


#pragma mark -

- (void)main
{
    // If we don’t have any unfinished tasks, finish immediately
    if (![self.subworkflow hasUnfinishedTasks]) {
        [self finish];
        return;
    }

    // If we were cancelled while checking to see if we have unfinished tasks, return
    if (!self.isExecuting) {
        return;
    }

    // Iterate over all the subworkflow’s tasks searching for the earliest failed task
    // and whether any tasks have been cancelled
    NSDate *earliestFinishDate = [NSDate distantFuture];
    TSKTask *failedTask = nil;
    BOOL foundCancelledTask = NO;

    for (TSKTask *task in self.subworkflow.allTasks) {
        if (task.isFailed && [task.finishDate compare:earliestFinishDate] < NSOrderedSame) {
            earliestFinishDate = task.finishDate;
            failedTask = task;
        }

        foundCancelledTask = foundCancelledTask || task.isCancelled;
    }

    // Prioritize failure behavior over cancellation behavior. Otherwise start.
    if (failedTask) {
        [self failWithError:failedTask.error];
    } else if (foundCancelledTask) {
        [self cancelWithoutPropagationToSubworkflow];
    } else {
        [self.subworkflow start];
    }
}


- (void)cancel
{
    [self.subworkflow cancel];
    [super cancel];
}


- (void)reset
{
    [self.subworkflow reset];
    [super reset];
}


- (void)retry
{
    [self.subworkflow retry];
    [super retry];
}


#pragma mark - State Changes

- (void)finish
{
    [self finishWithResult:self.subworkflow];
}


- (void)cancelWithoutPropagationToSubworkflow
{
    [super cancel];
}


#pragma mark - Subworkflow Task State

- (void)subworkflowDidFinish:(NSNotification *)notification
{
    [self finish];
}


- (void)subworkflowTaskDidFail:(NSNotification *)notification
{
    [self failWithError:[notification.userInfo[TSKWorkflowTaskKey] error]];
}


- (void)subworkflowTaskDidCancel:(NSNotification *)notification
{
    [self cancelWithoutPropagationToSubworkflow];
}

@end
