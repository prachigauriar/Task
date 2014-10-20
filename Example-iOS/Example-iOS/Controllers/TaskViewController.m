//
//  TaskViewController.m
//  Example-iOS
//
//  Created by Prachi Gauriar on 10/19/2014.
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

#import "TaskViewController.h"

#import <Task/Task.h>

#import "TaskCellController.h"
#import "TaskTableViewCell.h"
#import "TimeSlicedTask.h"


#pragma mark Constants

static NSString *const kTaskCellReuseIdentifier = @"TSKTaskViewController.TaskCell";


#pragma mark -

@interface TaskViewController () <UITableViewDataSource, UITableViewDelegate, TSKTaskDelegate>

/*! Our table view of tasks. */
@property (nonatomic, weak) IBOutlet UITableView *tableView;

/*! An array of controllers. The Nth element manages cell for the Nth row. */
@property (nonatomic, copy) NSArray *cellControllers;

/*! A cell we use to dynamically calculate heights for each row. */
@property (nonatomic, strong) TaskTableViewCell *prototypeCell;

/*! Our task graph and tasks. */
@property (nonatomic, strong) TSKGraph *taskGraph;
@property (nonatomic, strong) TSKTask *createProjectTask;
@property (nonatomic, strong) TSKExternalConditionTask *photo1AvailableCondition;
@property (nonatomic, strong) TSKTask *uploadPhoto1Task;
@property (nonatomic, strong) TSKExternalConditionTask *photo2AvailableCondition;
@property (nonatomic, strong) TSKTask *uploadPhoto2Task;
@property (nonatomic, strong) TSKExternalConditionTask *paymentInfoAvailableCondition;
@property (nonatomic, strong) TSKTask *submitOrderTask;

@end


#pragma mark -

@implementation TaskViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create our task graph and tasks
    [self initializeGraph];
    NSArray *tasks = @[ self.createProjectTask,
                        self.photo1AvailableCondition, self.uploadPhoto1Task,
                        self.photo2AvailableCondition, self.uploadPhoto2Task,
                        self.paymentInfoAvailableCondition, self.submitOrderTask ];

    // Create a cell controller for each task
    NSMutableArray *cellControllers = [[NSMutableArray alloc] initWithCapacity:tasks.count];
    for (TSKTask *task in tasks) {
        [cellControllers addObject:[[TaskCellController alloc] initWithTask:task]];
    }

    self.cellControllers = cellControllers;

    // Register our table view cell nib and create a prototype cell that we can use for cell height calculations
    [self.tableView registerNib:[TaskTableViewCell nib] forCellReuseIdentifier:kTaskCellReuseIdentifier];
    self.prototypeCell = [[[TaskTableViewCell nib] instantiateWithOwner:nil options:nil] firstObject];
}


- (void)initializeGraph
{
    self.taskGraph = [[TSKGraph alloc] initWithName:@"Task Graph"];

    // This task is completely independent of other tasks. Imagine that this creates a server resource that
    // we are going to update with additional data
    self.createProjectTask = [[TimeSlicedTask alloc] initWithName:@"Create Project Task" timeRequired:2.0];
    [self.taskGraph addTask:self.createProjectTask prerequisites:nil];

    // This is an external condition task that indicates that a photo is available. Imagine that this is
    // fulfilled when the user takes a photo or chooses a photo from their library for this project.
    self.photo1AvailableCondition = [[TSKExternalConditionTask alloc] initWithName:@"Photo 1 Available"];
    [self.taskGraph addTask:self.photo1AvailableCondition prerequisites:nil];

    // This uploads the first photo. It can’t run until the project is created and the photo is available
    self.uploadPhoto1Task = [[TimeSlicedTask alloc] initWithName:@"Upload Photo 1 Task" timeRequired:5.0];
    [self.taskGraph addTask:self.uploadPhoto1Task prerequisites:self.createProjectTask, self.photo1AvailableCondition, nil];

    // These are analagous to the previous two tasks, but for a second photo
    self.photo2AvailableCondition = [[TSKExternalConditionTask alloc] initWithName:@"Photo 2 Available"];
    self.uploadPhoto2Task = [[TimeSlicedTask alloc] initWithName:@"Upload Photo 2 Task" timeRequired:6.0];
    [self.taskGraph addTask:self.photo2AvailableCondition prerequisites:nil];
    [self.taskGraph addTask:self.uploadPhoto2Task prerequisites:self.createProjectTask, self.photo2AvailableCondition, nil];

    // This is an external condition task that indicates that some payment info has been entered. Imagine that
    // once the two photos are uploaded, the user is asked to purchase whatever it is they’re building.
    self.paymentInfoAvailableCondition = [[TSKExternalConditionTask alloc] initWithName:@"Payment Info Available"];
    [self.taskGraph addTask:self.paymentInfoAvailableCondition prerequisites:nil];

    // This submits an order. It can’t run until the photos are uploaded and the payment data is provided.
    self.submitOrderTask = [[TimeSlicedTask alloc] initWithName:@"Submit Order Task" timeRequired:2.0];
    [self.taskGraph addTask:self.submitOrderTask prerequisites:self.uploadPhoto1Task, self.uploadPhoto2Task, self.paymentInfoAvailableCondition, nil];

    [[self.taskGraph allTasks] makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cellControllers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTaskCellReuseIdentifier forIndexPath:indexPath];
    TaskCellController *controller = self.cellControllers[indexPath.row];
    [controller configureCell:cell forRowAtIndexPath:indexPath inTableView:tableView];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.cellControllers[indexPath.row] configureCell:self.prototypeCell forRowAtIndexPath:nil inTableView:nil];
    CGSize compressedSize = [self.prototypeCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return compressedSize.height;
}


- (NSIndexPath *)indexPathForTask:(TSKTask *)task
{
    NSUInteger row = [self.cellControllers indexOfObjectPassingTest:^BOOL(TaskCellController *cellController, NSUInteger index, BOOL *stop) {
        return cellController.task == task;
    }];

    return [NSIndexPath indexPathForRow:row inSection:0];
}


#pragma mark - Task Delegate

- (void)task:(TSKTask *)task didTransitionFromState:(TSKTaskState)fromState toState:(TSKTaskState)toState
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[ [self indexPathForTask:task] ] withRowAnimation:UITableViewRowAnimationNone];
    });
}

@end
