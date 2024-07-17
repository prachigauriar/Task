//
//  TSKSelectorTaskTestCase.m
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


@interface TSKSelectorTaskTestCase : TSKRandomizedTestCase

@property (nonatomic, assign) BOOL methodInvoked;
@property (nonatomic, strong) TSKTask *task;

- (void)testInit;
- (void)testMain;

@end


@implementation TSKSelectorTaskTestCase

- (void)testInit
{
    id nilObject = nil;
    SEL nullSelector = NULL;
    XCTAssertThrows(([[TSKSelectorTask alloc] initWithTarget:self selector:nullSelector]), @"NULL selector does not throw exception");
    XCTAssertThrows(([[TSKSelectorTask alloc] initWithTarget:nilObject selector:@selector(description)]), @"nil target does not throw exception");

    TSKSelectorTask *task = [[TSKSelectorTask alloc] initWithTarget:self selector:@selector(method:)];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqual(task.target, self, @"target is set incorrectly");
    XCTAssertEqual(task.selector, @selector(method:), @"method is set incorrectly");
    XCTAssertEqualObjects(task.requiredPrerequisiteKeys, [NSSet set], @"requiredPrerequisiteKeys is not the empty set");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKSelectorTask alloc] initWithName:name target:self selector:@selector(method:)];
    XCTAssertEqual(task.target, self, @"target is set incorrectly");
    XCTAssertEqual(task.selector, @selector(method:), @"method is set incorrectly");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
    XCTAssertEqualObjects(task.requiredPrerequisiteKeys, [NSSet set], @"requiredPrerequisiteKeys is not the empty set");

    NSSet *requiredPrerequisiteKeys = UMKGeneratedSetWithElementCount(random() % 5 + 5, ^id{
        return UMKRandomIdentifierString();
    });

    task = [[TSKSelectorTask alloc] initWithName:name target:self selector:@selector(method:) requiredPrerequisiteKeys:requiredPrerequisiteKeys];
    XCTAssertEqual(task.target, self, @"target is set incorrectly");
    XCTAssertEqual(task.selector, @selector(method:), @"method is set incorrectly");
    XCTAssertEqualObjects(task.name, name, @"name is set incorrectly");
    XCTAssertEqualObjects(task.requiredPrerequisiteKeys, requiredPrerequisiteKeys, @"requiredPrerequisiteKeys is set incorrectly");
}


- (void)testMain
{
    self.methodInvoked = NO;

    TSKSelectorTask *task = [[TSKSelectorTask alloc] initWithTarget:self selector:@selector(method:)];

    XCTAssertFalse(self.methodInvoked, @"selector called early");
    [task main];
    XCTAssertTrue(self.methodInvoked, @"selector not called");
    XCTAssertEqual(self.task, task, @"incorrect task parameter");
}


- (void)method:(TSKTask *)task
{
    self.methodInvoked = YES;
    self.task = task;
}

@end
