//
//  TaskCellController.m
//  Example-iOS
//
//  Created by Prachi Gauriar on 10/19/2014.
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

#import "TaskCellController.h"

#import <Task/Task.h>

#import "TaskTableViewCell.h"
#import "TimeSlicedTask.h"


@implementation TaskCellController

- (instancetype)init
{
    return [self initWithTask:nil];
}


- (instancetype)initWithTask:(TSKTask *)task
{
    NSParameterAssert(task);

    // Otherwise, just do initialization as usual
    self = [super init];
    if (self) {
        _task = task;
    }

    return self;
}


- (void)configureCell:(TaskTableViewCell *)cell
{
    // Set the background according to the task’s state
    if (self.task.isFinished) {
        cell.backgroundColor = [UIColor colorWithRed:0.96 green:1.0 blue:0.95 alpha:1.0];
    } else if (self.task.isFailed) {
        cell.backgroundColor = [UIColor colorWithRed:1.0 green:0.89 blue:0.90 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }

    // Set the cell’s name, state, and prerequisite labels
    cell.nameLabel.text = self.task.name;
    cell.stateLabel.text = TSKTaskStateDescription(self.task.state);

    NSArray *prerequisites = [[[self.task.prerequisiteTasks valueForKey:@"name"] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    cell.prerequisitesLabel.text = prerequisites.count > 0 ? [prerequisites componentsJoinedByString:@"\n"] : @"None";

    cell.progressView.progress = self.task.isFinished ? 1.0 : 0.0;

    // Button configuration is complicated…
    [self configureActionButton:cell.actionButton];
}


- (void)configureActionButton:(UIButton *)button
{
    // Get rid of any existing targets
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventAllTouchEvents];

    // Otherwise, we can start, cancel, retry, or reset the tasks
    switch (self.task.state) {
        case TSKTaskStatePending:
            [button setTitle:@"N/A" forState:UIControlStateNormal];
            button.enabled = NO;
            break;
        case TSKTaskStateReady:
            [button setTitle:@"Start" forState:UIControlStateNormal];
            button.enabled = YES;
            [button addTarget:self action:@selector(startTask) forControlEvents:UIControlEventTouchUpInside];
            break;
        case TSKTaskStateExecuting:
            [button setTitle:@"Cancel" forState:UIControlStateNormal];
            button.enabled = YES;
            [button addTarget:self action:@selector(cancelTask) forControlEvents:UIControlEventTouchUpInside];
            break;
        case TSKTaskStateCancelled:
        case TSKTaskStateFailed:
            [button setTitle:@"Retry" forState:UIControlStateNormal];
            button.enabled = YES;
            [button addTarget:self action:@selector(retryTask) forControlEvents:UIControlEventTouchUpInside];
            break;
        case TSKTaskStateFinished:
            [button setTitle:@"Reset" forState:UIControlStateNormal];
            button.enabled = YES;
            [button addTarget:self action:@selector(resetTask) forControlEvents:UIControlEventTouchUpInside];
            break;
        default:
            break;
    }
}


- (void)startTask
{
    [self.task start];
}


- (void)cancelTask
{
    [self.task cancel];
}


- (void)retryTask
{
    [self.task retry];
}


- (void)resetTask
{
    [self.task reset];
}

@end


#pragma mark - TimeSlicedTask Cell Controller

@implementation TimeSlicedTaskCellController

- (TimeSlicedTask *)timeSlicedTask
{
    return (TimeSlicedTask *)self.task;
}


- (void)configureCell:(TaskTableViewCell *)cell
{
    [super configureCell:cell];
    cell.progressView.progress = [self.timeSlicedTask progress];
}


- (void)setCell:(TaskTableViewCell *)cell
{
    [super setCell:cell];

    self.timeSlicedTask.progressBlock = !cell ? nil : ^(TimeSlicedTask *task) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [cell.progressView setProgress:task.progress animated:YES];
        }];
    };
}

@end


#pragma mark - TSKExternalConditionTask Cell Controller

@implementation ExternalConditionTaskCellController

- (TSKExternalConditionTask *)externalConditionTask
{
    return (TSKExternalConditionTask *)self.task;
}


- (void)configureActionButton:(UIButton *)button
{
    // Get rid of any existing targets
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventAllTouchEvents];

    if (![self.externalConditionTask isFulfilled]) {
        [button setTitle:@"Fulfill" forState:UIControlStateNormal];
        button.enabled = YES;
        [button addTarget:self action:@selector(fulfillConditionTask) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [button setTitle:@"Reset" forState:UIControlStateNormal];
        button.enabled = YES;
        [button addTarget:self action:@selector(resetTask) forControlEvents:UIControlEventTouchUpInside];
    }
}


- (void)fulfillConditionTask
{
    [(TSKExternalConditionTask *)self.task fulfillWithResult:nil];
}

@end


#pragma mark - TaskCellControllerCreation category

@implementation TSKTask (TaskCellControllerCreation)

- (TaskCellController *)createTaskCellController
{
    return [[TaskCellController alloc] initWithTask:self];
}

@end


#pragma mark -

@implementation TimeSlicedTask (TaskCellControllerCreation)

- (TaskCellController *)createTaskCellController
{
    return [[TimeSlicedTaskCellController alloc] initWithTask:self];
}

@end


#pragma mark -

@implementation TSKExternalConditionTask (TaskCellControllerCreation)

- (TaskCellController *)createTaskCellController
{
    return [[ExternalConditionTaskCellController alloc] initWithTask:self];
}

@end
