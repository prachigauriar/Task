//
//  TSKTask+WorkflowInterface.h
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

#import <Task/TSKTask.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 The WorkflowInterface category of TSKTask declares messages that must be exposed so that
 TSKWorkflows can modify the internal state of their TSKTasks.
 */
@interface TSKTask (WorkflowInterface)

@property (nonatomic, weak, readwrite, nullable) TSKWorkflow *workflow;

/*!
 @abstract Returns a recursive description of the task and its dependent tasks starting at the
     specified depth.
 @param depth The number of levels deep this task is in the recursive description.
 @result A recursive description of the task and its dependent tasks starting at the specified depth.
 */
- (NSString *)recursiveDescriptionWithDepth:(NSUInteger)depth;

/*!
 @abstract Indicates to the task that it has a prerequisite.
 @discussion This has the effect of transitioning the task from the ready state to the pending
     state.
 */
- (void)didAddPrerequisiteTask;

@end

NS_ASSUME_NONNULL_END
