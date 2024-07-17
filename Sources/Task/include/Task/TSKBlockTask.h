//
//  TSKBlockTask.h
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
 TSKBlockTasks perform a task’s work by executing a block. Together with TSKSelectorTask and 
 TSKExternalConditionTask, this obviates the need to subclass TSKTask in most circumstances.
 */
@interface TSKBlockTask : TSKTask

/*! 
 @abstract The block that performs the task’s work.
 @discussion May not be nil. This block takes the place of a TSKTask’s ‑main method. As such, the
     block must invoke ‑finishWithResult: or ‑failWithError: on the supplied task parameter upon
     success and failure, respectively. Failing to do so will prevent dependent tasks from executing.
     
     This block should also periodically check whether the task has been marked as cancelled and, if
     so, stop executing at the earliest possible moment.
 */
@property (nonatomic, copy, readonly) void (^block)(TSKTask *task);

/*!
 @abstract -init is unavailable, as there is no reasonable default value for the instance’s block.
 @discussion Use -initWithBlock: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @abstract -initWithName: is unavailable, as there is no reasonable default value for the instance’s 
     block.
 @discussion Use -initWithName:block: instead.
 */
- (instancetype)initWithName:(nullable NSString *)name NS_UNAVAILABLE;

/*!
 @abstract Initializes a newly created TSKBlockTask instance with the specified block.
 @discussion A default name will be given to the task as specified by TSKTask’s ‑initWithName:.
     Furthermore, The task’s set of required prerequisite keys is the empty set.
 @param block The block that performs the task’s work. May not be nil.
 @result A newly initialized TSKBlockTask instance with the specified block.
 */
- (instancetype)initWithBlock:(void (^)(TSKTask *task))block;

/*!
 @abstract Initializes a newly created TSKBlockTask instance with the specified name and block.
 @discussion The task’s set of required prerequisite keys is the empty set.
 @param name The name of the task. If nil, a default name will be given to the task as specified by
     TSKTask’s ‑initWithName:.
 @param block The block that performs the task’s work. May not be nil.
 @result A newly initialized TSKBlockTask instance with the specified name and block.
 */
- (instancetype)initWithName:(nullable NSString *)name block:(void (^)(TSKTask *task))block;

/*!
 @abstract Initializes a newly created TSKBlockTask instance with the specified name, required 
     prerequisite keys, and block.
 @discussion This is the class’s designated initializer.
 @param name The name of the task. If nil, a default name will be given to the task as specified by
     TSKTask’s ‑initWithName:.
 @param requiredPrerequisiteKeys The prerequisite keys that the task requires to run. If nil, no 
     prerequisite keys are required.
 @param block The block that performs the task’s work. May not be nil.
 @result A newly initialized TSKBlockTask instance with the specified name and block.
 */
- (instancetype)initWithName:(nullable NSString *)name
    requiredPrerequisiteKeys:(nullable NSSet<id<NSCopying>> *)requiredPrerequisiteKeys
                       block:(void (^)(TSKTask *task))block NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
