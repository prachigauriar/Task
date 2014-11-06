//
//  TSKSelectorTaskTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/5/14.
//  Copyright (c) 2014 Two Toasters, LLC. All rights reserved.
//

#import "TSKRandomizedTestCase.h"
@interface TSKSelectorTaskTestCase : TSKRandomizedTestCase

@property (nonatomic, assign) BOOL selectorCalled;
@property (nonatomic, strong) TSKTask *taskProperty;


@end

@implementation TSKSelectorTaskTestCase

- (void)testInit
{
    XCTAssertThrows(([[TSKSelectorTask alloc] initWithTarget:self selector:nil]), @"nil selector does not throw exception");
    XCTAssertThrows(([[TSKSelectorTask alloc] initWithTarget:nil selector:@selector(description)]), @"nil target does not throw exception");

    TSKSelectorTask *task = [[TSKSelectorTask alloc] initWithTarget:self selector:@selector(method:)];
    XCTAssertNotNil(task, @"returns nil");
    XCTAssertEqual(task.target, self, @"target not set propertly");
    XCTAssertEqual(task.selector, @selector(method:), @"method not set propertly");
    XCTAssertEqualObjects(task.name, [self defaultNameForTask:task], @"name not set to default");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");

    NSString *name = UMKRandomUnicodeString();
    task = [[TSKSelectorTask alloc] initWithName:name target:self selector:@selector(method:)];
    XCTAssertEqual(task.target, self, @"target not set propertly");
    XCTAssertEqual(task.selector, @selector(method:), @"method not set propertly");
    XCTAssertEqualObjects(task.name, name, @"name not set properly");
    XCTAssertNil(task.graph, @"graph is non-nil");
    XCTAssertNil(task.prerequisiteTasks, @"prerequisiteTasks is non-nil");
    XCTAssertNil(task.dependentTasks, @"dependentTasks is non-nil");
    XCTAssertEqual(task.state, TSKTaskStateReady, @"state not set to default");
}

- (void)testMain
{
    self.selectorCalled = NO;

    TSKSelectorTask *task = [[TSKSelectorTask alloc] initWithTarget:self selector:@selector(method:)];

    XCTAssertFalse(self.selectorCalled, @"selector called early");
    [task main];
    XCTAssertTrue(self.selectorCalled, @"selector not called");
    XCTAssertEqual(self.taskProperty, task, @"incorrect task parameter");
}


- (void)method:(TSKTask *)task
{
    self.selectorCalled = YES;
    self.taskProperty = task;
}

@end
