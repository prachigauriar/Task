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

static void *taskStateContext = &taskStateContext;
static NSString *const kTaskCellReuseIdentifier = @"TSKTaskViewController.TaskCell";


#pragma mark -

@interface TaskViewController () <UITableViewDataSource, UITableViewDelegate, TSKGraphDelegate>

/*! Our table view of tasks. */
@property (nonatomic, weak) IBOutlet UITableView *tableView;

/*! An array of controllers. The Nth element manages cell for the Nth row. */
@property (nonatomic, copy) NSArray *cellControllers;

/*! A cell we use to dynamically calculate heights for each row. */
@property (nonatomic, strong) TaskTableViewCell *prototypeCell;

/*! Our task graph and tasks (in the order we want them displayed). */
@property (nonatomic, strong) TSKGraph *taskGraph;
@property (nonatomic, copy) NSArray *tasks;

@end


#pragma mark -

@implementation TaskViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create our task graph and tasks
    [self initializeGraph];

    self.title = self.taskGraph.name;

    // Create a cell controller for each task
    NSMutableArray *cellControllers = [[NSMutableArray alloc] initWithCapacity:self.tasks.count];
    for (TSKTask *task in self.tasks) {
        [cellControllers addObject:[task createTaskCellController]];
        [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionInitial context:taskStateContext];
    }

    self.cellControllers = cellControllers;

    // Register our table view cell nib and create a prototype cell that we can use for cell height calculations
    [self.tableView registerNib:[TaskTableViewCell nib] forCellReuseIdentifier:kTaskCellReuseIdentifier];
    self.prototypeCell = [[[TaskTableViewCell nib] instantiateWithOwner:nil options:nil] firstObject];
}


- (void)initializeGraph
{
    self.taskGraph = [[TSKGraph alloc] initWithName:@"Order Product Workflow"];
    self.taskGraph.delegate = self;

    // This task is completely independent of other tasks. Imagine that this creates a server resource that
    // we are going to update with additional data
    TimeSlicedTask *createProjectTask = [[TimeSlicedTask alloc] initWithName:@"Create Project" timeRequired:2.0];
    createProjectTask.probabilityOfFailure = 0.1;
    [self.taskGraph addTask:createProjectTask prerequisites:nil];

    // This is an external condition task that indicates that a photo is available. Imagine that this is
    // fulfilled when the user takes a photo or chooses a photo from their library for this project.
    TSKTask *photo1AvailableCondition = [[TSKExternalConditionTask alloc] initWithName:@"Photo 1 Available"];
    [self.taskGraph addTask:photo1AvailableCondition prerequisites:nil];

    // This uploads the first photo. It can’t run until the project is created and the photo is available
    TimeSlicedTask *uploadPhoto1Task = [[TimeSlicedTask alloc] initWithName:@"Upload Photo 1" timeRequired:5.0];
    uploadPhoto1Task.probabilityOfFailure = 0.15;
    [self.taskGraph addTask:uploadPhoto1Task prerequisites:createProjectTask, photo1AvailableCondition, nil];

    // These are analagous to the previous two tasks, but for a second photo
    TSKTask *photo2AvailableCondition = [[TSKExternalConditionTask alloc] initWithName:@"Photo 2 Available"];
    TimeSlicedTask *uploadPhoto2Task = [[TimeSlicedTask alloc] initWithName:@"Upload Photo 2" timeRequired:6.0];
    uploadPhoto1Task.probabilityOfFailure = 0.15;

    [self.taskGraph addTask:photo2AvailableCondition prerequisites:nil];
    [self.taskGraph addTask:uploadPhoto2Task prerequisites:createProjectTask, photo2AvailableCondition, nil];

    // This is an external condition task that indicates that some metadata has been entered. Imagine that
    // once the two photos are uploaded, the user is asked to name the project.
    TSKTask *metadataAvailableCondition = [[TSKExternalConditionTask alloc] initWithName:@"Metadata Available"];
    [self.taskGraph addTask:metadataAvailableCondition prerequisites:nil];

    // This submits an order. It can’t run until the photos are uploaded and the metadata is provided.
    TimeSlicedTask *submitOrderTask = [[TimeSlicedTask alloc] initWithName:@"Submit Order" timeRequired:2.0];
    submitOrderTask.probabilityOfFailure = 0.1;
    [self.taskGraph addTask:submitOrderTask prerequisites:uploadPhoto1Task, uploadPhoto2Task, metadataAvailableCondition, nil];

    self.tasks = @[ createProjectTask,
                    photo1AvailableCondition, uploadPhoto1Task,
                    photo2AvailableCondition, uploadPhoto2Task,
                    metadataAvailableCondition, submitOrderTask ];
}


- (void)dealloc
{
    for (TSKTask *task in [self.taskGraph allTasks]) {
        [task removeObserver:self forKeyPath:@"state" context:taskStateContext];
    }
}


#pragma mark - Table View Data Source and Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cellControllers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTaskCellReuseIdentifier forIndexPath:indexPath];
    TaskCellController *controller = self.cellControllers[indexPath.row];
    controller.cell = cell;
    [controller configureCell:cell];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.cellControllers[indexPath.row] configureCell:self.prototypeCell];
    CGSize compressedSize = [self.prototypeCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return compressedSize.height;
}


- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    TaskCellController *cellController = self.cellControllers[indexPath.row];
    cellController.cell = nil;
}


- (NSIndexPath *)indexPathForTask:(TSKTask *)task
{
    NSUInteger row = [self.cellControllers indexOfObjectPassingTest:^BOOL(TaskCellController *cellController, NSUInteger index, BOOL *stop) {
        return cellController.task == task;
    }];

    return [NSIndexPath indexPathForRow:row inSection:0];
}


#pragma mark - Task State Changes

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != taskStateContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    TSKTask *task = object;

    NSIndexPath *indexPath = [self indexPathForTask:task];
    TaskCellController *controller = self.cellControllers[indexPath.row];

    if (controller.cell) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [controller configureCell:controller.cell];
        }];
    }
}


#pragma mark - Task Graph Delegate

- (void)graphDidFinish:(TSKGraph *)graph
{
    __weak typeof(self) weak_self = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        typeof(self) strong_self = weak_self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Tasks Finished"
                                                                                 message:@"All tasks finished succesffully."
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

        [strong_self presentViewController:alertController animated:YES completion:nil];
    }];
}


- (void)graph:(TSKGraph *)graph task:(TSKTask *)task didFailWithError:(NSError *)error
{
    if ([task isKindOfClass:[TSKExternalConditionTask class]]) {
        return;
    }

    __weak typeof(self) weak_self = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        typeof(self) strong_self = weak_self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Task Failed"
                                                                                 message:[NSString stringWithFormat:@"%@ failed.", task.name]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

        [alertController addAction:[UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [task retry];
        }]];

        [strong_self presentViewController:alertController animated:YES completion:nil];
    }];
}

@end
