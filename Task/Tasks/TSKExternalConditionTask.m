//
//  TSKExternalConditionTask.m
//  Task
//
//  Created by Prachi Gauriar on 10/14/2014.
//  Copyright (c) 2015 Ticketmaster. All rights reserved.
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

#import <Task/TSKExternalConditionTask.h>

#import <Task/TaskErrors.h>


@interface TSKExternalConditionTask ()

@property (nonatomic, strong, readonly) dispatch_queue_t fulfillmentQueue;
@property (nonatomic, strong) id fulfillmentResult;
@property (nonatomic, readwrite, assign, getter = isFulfilled) BOOL fulfilled;

@end


#pragma mark -

@implementation TSKExternalConditionTask

- (instancetype)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    if (self) {
        NSString *fulfillmentQueueName = [NSString stringWithFormat:@"com.twotoasters.TSKExternalConditionTask.%@.fulfillment", self.name];
        _fulfillmentQueue = dispatch_queue_create([fulfillmentQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return self;
}


- (void)main
{
    dispatch_sync(self.fulfillmentQueue, ^{
        if (self.isFulfilled) {
            [self finishWithResult:self.fulfillmentResult];
        } else {
            [self failWithError:[NSError errorWithDomain:TSKTaskErrorDomain code:TSKErrorCodeExternalConditionNotFulfilled userInfo:nil]];
        }
    });
}


- (void)fulfillWithResult:(id)result
{
    __block BOOL didFulfill = NO;
    dispatch_sync(self.fulfillmentQueue, ^{
        if (self.isFulfilled) {
            return;
        }

        self.fulfilled = YES;
        self.fulfillmentResult = result;
        didFulfill = YES;
    });

    if (didFulfill) {
        TSKTaskState state = self.state;
        if (state == TSKTaskStateCancelled || state == TSKTaskStateFailed) {
            [self retry];
        } else if (state == TSKTaskStateReady) {
            [self start];
        }
    }
}


- (void)reset
{
    dispatch_sync(self.fulfillmentQueue, ^{
        self.fulfilled = NO;
        self.fulfillmentResult = nil;
    });
    
    [super reset];
}

@end
