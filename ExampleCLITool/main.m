//
//  main.m
//  ExampleCLITool
//
//  Created by Prachi Gauriar on 10/18/2014.
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

#import <Foundation/Foundation.h>

#import <TaskKit/TaskKit.h>


@interface TSKTaskTest : NSObject <TSKTaskDelegate>

@property (nonatomic, strong) TSKGraph *graph;
@property (nonatomic, strong) TSKExternalConditionTask *f;
- (void)start;

@end


#pragma mark -

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        TSKTaskTest *taskTest = [[TSKTaskTest alloc] init];
        [taskTest start];
    }

    return 0;
}


#pragma mark -

@implementation TSKTaskTest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _graph = [[TSKGraph alloc] initWithName:@"Test Tasks"];
        [self initializeGraph];
    }

    return self;
}


- (void)initializeGraph
{
    __weak typeof(self) weak_self = self;
    void (^taskBlock)(TSKTask *) = ^(TSKTask *task) {
        [weak_self executeTask:task];
    };

    TSKBlockTask *a = [[TSKBlockTask alloc] initWithName:@"A" block:taskBlock];
    TSKBlockTask *b = [[TSKBlockTask alloc] initWithName:@"B" block:taskBlock];
    TSKBlockTask *c = [[TSKBlockTask alloc] initWithName:@"C" block:taskBlock];
    TSKBlockTask *d = [[TSKBlockTask alloc] initWithName:@"D" block:taskBlock];
    TSKBlockTask *e = [[TSKBlockTask alloc] initWithName:@"E" block:taskBlock];

    self.f = [[TSKExternalConditionTask alloc] initWithName:@"F"];
    TSKSelectorTask *g = [[TSKSelectorTask alloc] initWithName:@"G" target:self selector:@selector(executeTask:)];
    TSKSelectorTask *h = [[TSKSelectorTask alloc] initWithName:@"H" target:self selector:@selector(executeTask:)];
    TSKSelectorTask *i = [[TSKSelectorTask alloc] initWithName:@"I" target:self selector:@selector(executeTask:)];
    TSKSelectorTask *j = [[TSKSelectorTask alloc] initWithName:@"J" target:self selector:@selector(executeTask:)];
    TSKSelectorTask *k = [[TSKSelectorTask alloc] initWithName:@"K" target:self selector:@selector(executeTask:)];

    [self.graph addTask:a prerequisites:nil];
    [self.graph addTask:b prerequisites:nil];

    [self.graph addTask:c prerequisites:a, nil];
    [self.graph addTask:d prerequisites:a, nil];
    [self.graph addTask:e prerequisites:a, b, nil];
    [self.graph addTask:self.f prerequisites:b, nil];

    [self.graph addTask:g prerequisites:c, nil];
    [self.graph addTask:h prerequisites:c, nil];
    [self.graph addTask:i prerequisites:d, nil];
    [self.graph addTask:j prerequisites:d, nil];
    [self.graph addTask:k prerequisites:d, e, self.f, nil];

    [[self.graph allTasks] makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
}


- (void)start
{
    [self.graph start];
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}


- (void)executeTask:(TSKTask *)task
{
    NSLog(@"%@ did start.", task);

    NSTimeInterval timeSlice = 0.25;
    NSTimeInterval runTimeInterval = (arc4random_uniform(3) + 1) * timeSlice;

    while (!task.isCancelled && runTimeInterval > 0.0) {
        [NSThread sleepForTimeInterval:timeSlice];
        runTimeInterval -= timeSlice;
    }

    if (task.isCancelled) {
        NSLog(@"%@ was cancelled", task);
    }

    if (arc4random_uniform(5) != 0) {
        [task finishWithResult:task.name];
    } else {
        [task failWithError:[NSError errorWithDomain:@"prachi" code:1234 userInfo:nil]];
    }
}


- (void)task:(TSKTask *)task didFinishWithResult:(id)result
{
    NSLog(@"%@ finished with result %p.\n%@\n\n", task, result, [self.graph debugDescription]);

    if ([task.name isEqualToString:@"B"]) {
        [self.graph.operationQueue addOperationWithBlock:^{
            [NSThread sleepForTimeInterval:0.5];
            [self.f fulfillWithResult:task.name];
        }];
    }

    if (arc4random_uniform(8) == 0) {
        NSLog(@"Cancelling all tasks.");
        [self.graph cancel];
    }

    if (![self.graph hasUnfinishedTasks]) {
        NSLog(@"All tasks complete");
    }
}


- (void)task:(TSKTask *)task didFailWithError:(NSError *)error
{
    NSLog(@"%@ failed with error %p.\n%@\n\n", task, error, [self.graph debugDescription]);

    if (arc4random_uniform(3) == 0) {
        NSLog(@"Retrying %@.", task);
        [self.graph retry];
    }
}

@end
