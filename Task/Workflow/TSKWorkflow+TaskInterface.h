//
//  TSKWorkflow+TaskInterface.h
//  Task
//
//  Created by Prachi Gauriar on 11/16/2014.
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

#import <Task/TSKWorkflow.h>


/*!
 The TaskInterface category of TSKWorkflow declares messages that must be exposed so that TSKTasks
 can notify their workflows of state changes.
 */
@interface TSKWorkflow (TaskInterface)

/*!
 @abstract Indicates to the receiver that the specified task finished successfully.
 @param task The task that finished. May not be nil.
 @param result The result that the task finished with.
 */
- (void)subtask:(TSKTask *)task didFinishWithResult:(id)result;

/*!
 @abstract Indicates to the receiver that the specified task failed.
 @param task The task that failed. May not be nil.
 @param error The error that caused the task to fail.
 */
- (void)subtask:(TSKTask *)task didFailWithError:(NSError *)error;

/*!
 @abstract Indicates to the receiver that the specified task was cancelled.
 @param task The task that was cancelled. May not be nil.
 */
- (void)subtaskDidCancel:(TSKTask *)task;

/*!
 @abstract Indicates to the receiver that the specified task was reset.
 @param task The task that was reset. May not be nil.
 */
- (void)subtaskDidReset:(TSKTask *)task;

@end
