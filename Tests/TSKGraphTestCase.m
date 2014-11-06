//
//  TSKGraphTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/4/14.
//  Copyright (c) 2014 Two Toasters, LLC. All rights reserved.
//

#import "TSKRandomizedTestCase.h"

@interface TSKGraphTestCase : TSKRandomizedTestCase

@end

@implementation TSKGraphTestCase

- (void)testInit
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    XCTAssertNotNil(graph, @"returns nil");
    XCTAssertEqualObjects(graph.allTasks, [NSSet set]);
    XCTAssertEqualObjects(graph.name, ([NSString stringWithFormat:@"TSKGraph %p", graph]), @"name not set to default");
    XCTAssertNotNil(graph.operationQueue, @"operation queue not set to default");
    XCTAssertEqualObjects(graph.operationQueue.name, ([NSString stringWithFormat:@"com.twotoasters.TSKGraph.TSKGraph %p", graph]), @"name not set to default");

    NSString *graphName = UMKRandomUnicodeString();
    NSString *queueName = UMKRandomUnicodeString();
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = queueName;
    graph = [[TSKGraph alloc] initWithName:graphName operationQueue:queue];
    XCTAssertNotNil(graph, @"returns nil");
    XCTAssertEqualObjects(graph.allTasks, [NSSet set]);
    XCTAssertEqualObjects(graph.name, graphName, @"name not set properly");
    XCTAssertEqual(graph.operationQueue, queue, @"operation queue not set properly");
    XCTAssertEqualObjects(graph.operationQueue.name, queueName, @"name not properly");
}

- (void)testAddTasks
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTask *task = [[TSKTask alloc] init];
    [graph addTask:task prerequisites:nil];
    XCTAssertEqualObjects([graph prerequisiteTasksForTask:task], [NSSet set], @"prereqs not set");
    XCTAssertEqualObjects([graph dependentTasksForTask:task], [NSSet set], @"prereqs not set");


    TSKTask *dependent = [[TSKTask alloc] init];
    [graph addTask:dependent prerequisites:task, nil];

    XCTAssertEqualObjects([graph prerequisiteTasksForTask:dependent], [NSSet setWithObject:task], @"prereqs not set property");
    XCTAssertEqualObjects([graph dependentTasksForTask:task], [NSSet setWithObject:dependent], @"prereqs not set property");
    XCTAssertEqualObjects([graph allTasks], ([NSSet setWithObjects:task, dependent, nil]), @"all tasks not set property");
    XCTAssertEqualObjects([graph tasksWithNoPrerequisiteTasks], ([NSSet setWithObjects:task, nil]), @"tasksWithNoPrerequisiteTasks not set correctly");
    XCTAssertEqualObjects([graph tasksWithNoDependentTasks], ([NSSet setWithObjects:dependent, nil]), @"tasksWithNoDependentTasks not set correctly");
}


@end
