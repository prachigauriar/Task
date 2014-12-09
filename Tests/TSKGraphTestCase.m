//
//  TSKGraphTestCase.m
//  Task
//
//  Created by Jill Cohen on 11/4/14.
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

#import "TSKRandomizedTestCase.h"


@interface TSKGraphTestCase : TSKRandomizedTestCase

- (void)testInit;
- (void)testAddTasks;

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
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    graph = [[TSKGraph alloc] initWithName:graphName operationQueue:queue];
    XCTAssertNotNil(graph, @"returns nil");
    XCTAssertEqualObjects(graph.allTasks, [NSSet set]);
    XCTAssertEqualObjects(graph.name, graphName, @"name not set properly");
    XCTAssertEqual(graph.operationQueue, queue, @"operation queue not set properly");
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
    XCTAssertEqualObjects([graph tasksWithNoPrerequisiteTasks], ([NSSet setWithObject:task]), @"tasksWithNoPrerequisiteTasks not set correctly");
    XCTAssertEqualObjects([graph tasksWithNoDependentTasks], ([NSSet setWithObject:dependent]), @"tasksWithNoDependentTasks not set correctly");
}


- (void)testAddTaskErrorCases
{
    TSKGraph *graph = [[TSKGraph alloc] init];
    TSKTask *task = [[TSKTask alloc] init];
    [graph addTask:task prerequisites:nil];
    XCTAssertThrows([graph addTask:task prerequisites:nil], @"adding a task to the same graph twice does not throw an exception");

    TSKGraph *otherGraph = [[TSKGraph alloc] init];
    XCTAssertThrows([otherGraph addTask:task prerequisites:nil], @"adding a task to a second graph does not throw an exception");

    TSKTask *prerequisiteTask = [[TSKTask alloc] init];
    TSKTask *dependentTask = [[TSKTask alloc] init];

    XCTAssertThrows(([graph addTask:dependentTask prerequisites:prerequisiteTask, nil]), @"graph allows a task to be added before its prerequisite is added");
}


- (void)testOperationQueue
{
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    TSKGraph *graph = [[TSKGraph alloc] initWithOperationQueue:operationQueue];
    XCTestExpectation *testDidRunExpectation = [self expectationWithDescription:@"test for operation queue did run"];

    TSKBlockTask *task = [[TSKBlockTask alloc] initWithBlock:^(TSKTask *task) {
        XCTAssertEqual(operationQueue, [NSOperationQueue currentQueue], @"task not executing on correct queue");
        [testDidRunExpectation fulfill];
    }];
    [graph addTask:task prerequisites:nil];
    [graph start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
