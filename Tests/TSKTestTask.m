//
//  TSKTestTask.m
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

#import "TSKTestTask.h"

NSString * const kTaskDidStartNotification = @"Task did start";
NSString * const kTaskDidFinishNotification = @"Task did finish";
NSString * const kTaskDidFailNotification = @"Task did fail";
NSString * const kTaskDidRetryNotification = @"Task did retry";
NSString * const kTaskDidResetNotification = @"Task did reset";
NSString * const kTaskDidCancelNotification = @"Task did cancel";


@implementation TSKTestTask


- (instancetype)initWithBlock:(void (^)(TSKTask *task))block
{
    return [self initWithName:nil block:block];
}


- (instancetype)initWithName:(NSString *)name block:(void (^)(TSKTask *task))block
{
    if (!block) {
        return [super initWithName:nil];
    }

    self = [super initWithName:nil];
    if (self) {
        _block = [block copy];
    }

    return self;
}

#pragma mark - Execution

- (void)main
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDidStartNotification object:self];

    if (self.block) {
        self.block(self);
    }
}

- (void)cancel
{
    [super cancel];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDidCancelNotification object:self];
}


- (void)reset
{
    [super reset];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDidResetNotification object:self];
}


- (void)retry
{
    [super retry];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDidRetryNotification object:self];

}


- (void)finishWithResult:(id)result
{
    [super finishWithResult:result];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDidFinishNotification object:self];
}


- (void)failWithError:(NSError *)error
{
    [super failWithError:error];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDidFailNotification object:self];
}

@end
