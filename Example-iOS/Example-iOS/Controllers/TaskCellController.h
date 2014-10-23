//
//  TSKTaskCellController.h
//  Example-iOS
//
//  Created by Prachi Gauriar on 10/19/2014.
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

@import UIKit;

#import <Task/Task.h>

@class TaskTableViewCell;
@class TimeSlicedTask;


/*!
 TaskCellControllers control a single TaskTableViewCell. They configure the cells and manage their
 appearance and actions.
 */
@interface TaskCellController : NSObject

/*! The controller’s task. May not be nil. */
@property (nonatomic, strong, readonly) TSKTask *task;

/*! The cell that the controller’s task is being displayed in. */
@property (nonatomic, strong) TaskTableViewCell *cell;

/*! 
 @abstract Initializes a newly created TaskCellController object with the specified task.
 @discussion This is the class’s designated initializer.
 @param task The task the controller manages. May not be nil.
 @result An initialized TaskCellController object with the specified task.
 */
- (instancetype)initWithTask:(TSKTask *)task NS_DESIGNATED_INITIALIZER;

/*!
 @abstract Configures the specified cell.
 @param cell The cell that should be configured.
 */
- (void)configureCell:(TaskTableViewCell *)cell;

@end


#pragma mark -

/*! 
 TimeSlicedTaskCellController control a single TaskTableViewCell for a TimeSlicedTask.
 */
@interface TimeSlicedTaskCellController : TaskCellController

/*! The receiver’s task as a TimeSlicedTask. */
@property (nonatomic, strong, readonly) TimeSlicedTask *timeSlicedTask;

@end


#pragma mark -

/*!
 ExternalConditionTaskCellController control a single TaskTableViewCell for a TSKExternalConditionTask.
 */
@interface ExternalConditionTaskCellController : TaskCellController

/*! The receiver’s task as a TSKExternalConditionTask. */
@property (nonatomic, strong, readonly) TSKExternalConditionTask *externalConditionTask;

@end


#pragma mark -

/*!
 The TaskCellControllerCreation interface provides a method to create a task cell controller
 of the appropriate type for a given TSKTask. This effectively negates the need to check a task’s type
 to create an appropriate task cell controller.
 */
@interface TSKTask (TaskCellControllerCreation)

/*!
 @abstract Creates a new task cell controller for the receiver.
 @result A new task cell controller for the receiver.
 */
- (TaskCellController *)createTaskCellController;

@end
