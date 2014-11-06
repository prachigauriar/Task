//
//  TSKBlockTaskTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/5/14.
//  Copyright (c) 2014 Two Toasters, LLC. All rights reserved.
//

#import "TSKRandomizedTestCase.h"

@interface TSKBlockTaskTestCase : TSKRandomizedTestCase

@end

@implementation TSKBlockTaskTestCase

- (void)testInit
{
    XCTAssertThrows(([[TSKBlockTask alloc] initWithBlock:nil]), @"nil block does not throw exception");

    void (^block)(TSKTask *) = ^void(TSKTask *task) { };

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:block];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqual(task.block, block, @"block not set propertly");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKBlockTask alloc] initWithName:name block:block];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqual(task.block, block, @"block not set properly");
    XCTAssertEqualObjects(task.name, name, @"name not set properly");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state not set to default");

    XCTAssertThrows(([[TSKBlockTask alloc] initWithName:name block:nil]), @"nil block does not throw exception");
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
