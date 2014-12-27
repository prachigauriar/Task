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
    self = [super initWithName:name];
    if (self) {
        _subworkflow = subworkflow;

        [subworkflow.notificationCenter addObserver:self
                                           selector:@selector(subworkflowDidFinish:)
                                               name:TSKWorkflowDidFinishNotification
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


- (void)main
{
    [self.subworkflow start];
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


- (void)subworkflowDidFinish:(NSNotification *)notification
{
    [self finishWithResult:nil];
}


- (void)subworkflowTaskDidFail:(NSNotification *)notification
{
    [self failWithError:[notification.userInfo[TSKWorkflowFailedTaskKey] error]];
}

@end
