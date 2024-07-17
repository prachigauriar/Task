//
//  TSKExternalConditionTask.h
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
 TSKExternalConditionTask is special type of task that performs no actual work. Instead, it
 represents an external condition that is either fulfilled or not. When run, the task will either
 finish successfully if it is fulfilled, or fail immediately with an error.

 When a TSKExternalConditionTask is fulfilled, it will automatically start or retry itself and thus
 its dependent tasks.
 */
@interface TSKExternalConditionTask : TSKTask

/*! Whether the task’s condition is fulfilled. This is initially NO. */
@property (nonatomic, readonly, assign, getter = isFulfilled) BOOL fulfilled;

/*!
 @abstract Indicates that the external condition is fulfilled.
 @param result The result that the task should finish with. May be nil.
 @discussion If the task is in the cancelled or failed state, it will automatically retry itself.
     Otherwise it will start itself if ready.
 */
- (void)fulfillWithResult:(nullable id)result NS_SWIFT_NAME(fulfill(with:));

@end

NS_ASSUME_NONNULL_END
