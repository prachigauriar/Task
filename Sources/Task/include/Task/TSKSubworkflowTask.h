//
//  TSKSubworkflowTask.h
//  Task
//
//  Created by Prachi Gauriar on 12/27/2014.
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
 A TSKSubworkflowTask is a task that executes a whole workflow, called a subworkflow, as its unit 
 of work. This is primarily intended for when you have an existing mechanism for creating a workflow
 that you wish to incorporate as a part of a larger workflow. If this does not describe your scenario,
 you are likely better off avoiding TSKSubworkflowTasks.

 A subworkflow task’s state reflects that of the tasks in its subworkflow. When the entire
 subworkflow finishes, the subworkflow task finishes; when a single task in the subworkflow fails
 with an error, the subworkflow task fails with that error. Finally, when a task in the subworkflow
 is cancelled, the entire subworkflow task is cancelled.

 Generally speaking, avoid starting a subworkflow task’s subworkflow before starting the subworkflow
 task itself. If, when a subworkflow task starts, it finds that its subworkflow is already finished,
 it will finish immediately. If the subworkflow contains one or more failed tasks, the subworkflow task
 will fail immediately with the earliest failed task’s error. Finally, if the subworkflow contains no 
 failed tasks but does contain one or more cancelled tasks, the subworkflow task will cancel itself
 immediately.

 When a subworkflow task finishes, its result is the subworkflow itself. This allows dependent tasks
 to unpack the results of the subworkflow in any way they see fit. This underscores a drawback of
 using subworkflow tasks: there is no natural way to communicate task results into and out of a
 subworkflow. A subworkflow’s initial tasks have no way of accessing the subworkflow task’s
 prerequisites, and the results of a subworkflow must be unpacked manually. In both situations, it
 is helpful to create result-forwarding tasks. These tasks get results from the relevant
 prerequisite tasks and finish with those results as their own. For example,

     TSKTask *prerequisite1, *prerequisite2, …, *prerequisiteN;
     TSKBlockTask *resultForwardingTask = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
         // Get the results from the prerequisite tasks, process them, and store them
         // in an appropriate object that we will finish with
         id result = …;

         [self finishWithResult:result];
     }];

 Tasks that need to use these results may then declare the result-forwarding task as a prerequisite.
 Using result-forwarding tasks as either the first tasks in a subworkflow or the first tasks after a
 subworkflow task can make it significantly easier to communicate results in and out of a
 subworkflow.
 */
@interface TSKSubworkflowTask : TSKTask

/*! The instance’s subworkflow. May not be nil. */
@property (nonatomic, strong, readonly) TSKWorkflow *subworkflow;


/*!
 @abstract -init is unavailable, as there is no reasonable default value for the instance’s subworkflow.
 @discussion Use -initWithSubworkflow: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @abstract -initWithName: is unavailable, as there is no reasonable default value for the instance’s
     subworkflow.
 @discussion Use -initWithName:subworkflow: instead.
 */
- (instancetype)initWithName:(nullable NSString *)name NS_UNAVAILABLE;


/*!
 @abstract Initializes a newly created TSKSubworkflowTask instance with the specified subworkflow.
 @discussion A default name will be given to the task as specified by TSKTask’s ‑initWithName:.
 @param subworkflow The subworkflow that the task starts in its ‑main method. May not be nil.
 @result A newly initialized TSKSubworkflowTask instance with the specified subworkflow.
 */
- (instancetype)initWithSubworkflow:(TSKWorkflow *)subworkflow;

/*!
 @abstract Initializes a newly created TSKSubworkflowTask instance with the specified name and 
     subworkflow.
 @discussion This is the class’s designated initializer.
 @param name The name of the task. If nil, a default name will be given to the task as specified by
     TSKTask’s ‑initWithName:.
 @param subworkflow The subworkflow that the task starts in its ‑main method. May not be nil.
 @result A newly initialized TSKSubworkflowTask instance with the specified name and subworkflow.
 */
- (instancetype)initWithName:(nullable NSString *)name subworkflow:(TSKWorkflow *)subworkflow NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
