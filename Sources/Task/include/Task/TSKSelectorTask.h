//
//  TSKSelectorTask.h
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
 TSKSelectorTasks perform a task’s work by sending a message to an object. Together with
 TSKBlockTask and TSKExternalConditionTask, this obviates the need to subclass TSKTask in most 
 circumstances.
 */
@interface TSKSelectorTask : TSKTask

/*!
 @abstract The receiver of the task’s message-send. 
 @discussion May not be nil.
 */
@property (nonatomic, weak, readonly, nullable) id target;

/*!
 @abstract The selector that the task’s target performs in order to do the task’s work. 
 @discussion May not be NULL. This selector must take a single parameter of type TSKTask *. 
 
     The method corresponding to this selector takes the place of a TSKTask’s ‑main method. As such,
     the method must invoke ‑finishWithResult: or ‑failWithError: on the supplied task parameter
     upon success and failure, respectively. Failing to do so will prevent dependent tasks from
     executing.
     
     The method should also periodically check whether the task has been marked as cancelled and, if
     so, stop executing at the earliest possible moment.
 */
@property (nonatomic, assign, readonly) SEL selector;

/*!
 @abstract -init is unavailable, as there is no reasonable default value for the instance’s target
     and selector.
 @discussion Use -initWithTarget:selector: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @abstract -initWithName: is unavailable, as there is no reasonable default value for the instance’s
     target and selector.
 @discussion Use -initWithName:target:selector: instead.
 */
- (instancetype)initWithName:(nullable NSString *)name NS_UNAVAILABLE;

/*!
 @abstract Initializes a newly created TSKSelectorTask instance with the specified target and
     selector.
 @discussion A default name will be given to the task as specified by TSKTask’s ‑initWithName:.
     Furthermore, the task’s set of required prerequisite keys is the empty set.
 @param target The receiver of the task’s message-send. May not be nil.
 @param selector The selector that the task’s target performs in order to do the task’s work. 
     May not be NULL.
 @result A newly initialized TSKSelectorTask instance with the specified target and action.
 */
- (instancetype)initWithTarget:(id)target selector:(SEL)selector;

/*!
 @abstract Initializes a newly created TSKSelectorTask instance with the specified name, target, and
     selector.
 @discussion The task’s set of required prerequisite keys is the empty set.
 @param name The name of the task. If nil, a default name will be given to the task as specified by
     TSKTask’s ‑initWithName:.
 @param target The receiver of the task’s message-send. May not be nil.
 @param selector The selector that the task’s target performs in order to do the task’s work. 
     May not be NULL.
 @result A newly initialized TSKSelectorTask instance with the specified name, target, and action.
 */
- (instancetype)initWithName:(nullable NSString *)name target:(id)target selector:(SEL)selector;


/*!
 @abstract Initializes a newly created TSKSelectorTask instance with the specified name, target,
     selector, and required prerequisite keys.
 @discussion This is the class’s designated initializer.
 @param name The name of the task. If nil, a default name will be given to the task as specified by
     TSKTask’s ‑initWithName:.
 @param target The receiver of the task’s message-send. May not be nil.
 @param selector The selector that the task’s target performs in order to do the task’s work.
     May not be NULL.
 @param requiredPrerequisiteKeys The prerequisite keys that the task requires to run. If nil, no
     prerequisite keys are required.
 @result A newly initialized TSKSelectorTask instance with the specified name, target, and action.
 */
- (instancetype)initWithName:(nullable NSString *)name
                      target:(id)target
                    selector:(SEL)selector
    requiredPrerequisiteKeys:(nullable NSSet<id<NSCopying>> *)requiredPrerequisiteKeys NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
