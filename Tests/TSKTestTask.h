//
//  TSKTestTask.h
//  Task
//
//  Created by Jill Cohen on 12/9/14.
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

#import <Task/Task.h>

#pragma mark Constants

extern NSString *const TSKTestTaskDidStartNotification;
extern NSString *const TSKTestTaskDidFinishNotification;
extern NSString *const TSKTestTaskDidFailNotification;
extern NSString *const TSKTestTaskDidRetryNotification;
extern NSString *const TSKTestTaskDidResetNotification;
extern NSString *const TSKTestTaskDidCancelNotification;


#pragma mark -
/*!
 TSKTestTask provides notifications for major events to enable testing with expectations.
 It can take a block that executes in -main after the TSKTestTaskDidStartNotification is posted. (The class is similar to TSKBlock, but it allows the block to be nil.)
*/
@interface TSKTestTask : TSKTask

@property (nonatomic, copy, readonly) void (^block)(TSKTask *task);

- (instancetype)initWithBlock:(void (^)(TSKTask *task))block;
- (instancetype)initWithName:(NSString *)name block:(void (^)(TSKTask *task))block;

@end
