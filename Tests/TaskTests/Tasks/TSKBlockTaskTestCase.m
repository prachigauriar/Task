//
//  TSKBlockTaskTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/5/14.
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

#import "TSKRandomizedTestCase.h"


@interface TSKBlockTaskTestCase : TSKRandomizedTestCase

- (void)testInit;
- (void)testMain;

@end


@implementation TSKBlockTaskTestCase

- (void)testInit
{
    id nilObject = nil;
    XCTAssertThrows(([[TSKBlockTask alloc] initWithBlock:nilObject]), @"nil block does not throw exception");

    void (^block)(TSKTask *) = ^void(TSKTask *task) { };

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:block];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.block, block, @"block is set incorrectly");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertEqualObjects(task.requiredPrerequisiteKeys, [NSSet set], @"requiredPrerequisiteKeys is not the empty set");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKBlockTask alloc] initWithName:name block:block];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.block, block, @"block is set incorrectly");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
    XCTAssertEqualObjects(task.requiredPrerequisiteKeys, [NSSet set], @"requiredPrerequisiteKeys is not the empty set");

    NSSet *requiredPrerequisiteKeys = UMKGeneratedSetWithElementCount(random() % 5 + 5, ^id{
        return UMKRandomIdentifierString();
    });

    task = [[TSKBlockTask alloc] initWithName:name requiredPrerequisiteKeys:requiredPrerequisiteKeys block:block];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqualObjects(task.block, block, @"block is set incorrectly");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
    XCTAssertEqualObjects(task.requiredPrerequisiteKeys, requiredPrerequisiteKeys, @"requiredPrerequisiteKeys is set incorrectly");

    XCTAssertThrows(([[TSKBlockTask alloc] initWithName:name requiredPrerequisiteKeys:nil block:nilObject]), @"nil block does not throw exception");
}


- (void)testMain
{
    __block BOOL blockInvoked = NO;
    __block TSKTask *taskParameter = nil;
    void (^block)(TSKTask *) = ^void(TSKTask *task) {
        blockInvoked = YES;
        taskParameter = task;
    };

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:block];

    XCTAssertFalse(blockInvoked, @"block invoked early");
    [task main];
    XCTAssertTrue(blockInvoked, @"block not invoked");
    XCTAssertEqual(taskParameter, task, @"incorrect task parameter");
}

@end
