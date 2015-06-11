//
//  TSKTestTask.m
//  Task
//
//  Created by Jill Cohen on 12/9/14.
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

#import "TSKTestTask.h"


NSString *const TSKTestTaskDidStartNotification = @"Task did start";
NSString *const TSKTestTaskDidFinishNotification = @"Task did finish";
NSString *const TSKTestTaskDidFailNotification = @"Task did fail";
NSString *const TSKTestTaskDidRetryNotification = @"Task did retry";
NSString *const TSKTestTaskDidResetNotification = @"Task did reset";
NSString *const TSKTestTaskDidCancelNotification = @"Task did cancel";


@implementation TSKTestTask

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name block:nil];
}


- (instancetype)initWithBlock:(void (^)(TSKTask *task))block
{
    return [self initWithName:nil block:block];
}


- (instancetype)initWithName:(NSString *)name block:(void (^)(TSKTask *task))block
{
    self = [super initWithName:nil];
    if (self) {
        _block = [block copy];
    }

    return self;
}


- (void)main
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TSKTestTaskDidStartNotification object:self];

    if (self.block) {
        self.block(self);
    }
}

- (void)cancel
{
    [super cancel];
    [[NSNotificationCenter defaultCenter] postNotificationName:TSKTestTaskDidCancelNotification object:self];
}


- (void)reset
{
    [super reset];
    [[NSNotificationCenter defaultCenter] postNotificationName:TSKTestTaskDidResetNotification object:self];
}


- (void)retry
{
    [super retry];
    [[NSNotificationCenter defaultCenter] postNotificationName:TSKTestTaskDidRetryNotification object:self];

}


- (void)finishWithResult:(id)result
{
    [super finishWithResult:result];
    [[NSNotificationCenter defaultCenter] postNotificationName:TSKTestTaskDidFinishNotification object:self];
}


- (void)failWithError:(NSError *)error
{
    [super failWithError:error];
    [[NSNotificationCenter defaultCenter] postNotificationName:TSKTestTaskDidFailNotification object:self];
}

@end
