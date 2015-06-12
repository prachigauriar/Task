//
//  TimeSlicedTask.h
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

#import <Task/Task.h>

/*!
 This is a very simple demo subclass of TSKTask. Each TimeSlicedTask instance has a total amount of time
 required to complete. When the task is executed, it will run in small time slices and update its total
 progress until it is complete. See the -main method for more details.
 */
@interface TimeSlicedTask : TSKTask

/*! The amount of time the task has run. */
@property (nonatomic, assign, readonly) NSTimeInterval timeTaken;

/*! The total amount of time the task must run before being complete. 0.0 by default. */
@property (nonatomic, assign, readonly) NSTimeInterval timeRequired;

/*! The probability that the task will fail. This should be a value between 0.0 and 1.0. 0.0 by default. */
@property (nonatomic, assign) double probabilityOfFailure;

/*! 
 @abstract The task’s progress (between 0.0 and 1.0, inclusive).
 @discussion If the task is in the executing state, returns timeTaken / timeRequired. If it is in the 
     finished state, returns 1.0. Otherwise returns 0.0.
 */
@property (nonatomic, assign, readonly) double progress;

/*!
 @abstract A block that is executed every time the task makes progress.
 @discussion This may be used to update a UI.
 */
@property (nonatomic, copy) void (^progressBlock)(TimeSlicedTask *);

/*!
 @abstract Initializes a newly created TimeSlicedTask with the specified name and time required.
 @param name The name of the task.
 @param timeRequired The total amount of time the task must run before being complete.
 @result An initialized TimeSlicedTask with the specified name and time required.
 */
- (instancetype)initWithName:(NSString *)name timeRequired:(NSTimeInterval)timeRequired NS_DESIGNATED_INITIALIZER;

@end
