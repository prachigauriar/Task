# Task.framework

Task is a simple Cocoa framework for expressing and executing your application’s workflows. Using
Task, you need only express each step in your workflow — called tasks — and what their prerequisite
tasks are. After that, the framework handles the mechanics of executing the steps in the correct
order with the appropriate level of concurrency, letting you know when tasks finish or fail. It also
makes it easy to cancel tasks, retry failed tasks, and re-run previously completed tasks and 
workflows.


## What’s New in 1.0

Task 1.0 adds numerous new features, but also makes a few significant API changes from Task 0.3 
that will break existing code. Thankfully, the changes are easy to accommodate.

### New Features

* Notifications for important task- and workflow-related events. Every workflow has a reference to a
  notification center that it and its tasks use to post notifications. By default, it is the default
  notification center, but you can use a different one should you so desire. Tasks post
  notifications when they start, finish, fail, cancel, retry, and reset. Workflows post
  notifications when they start, retry, and reset, as well as when all their tasks finish, or a
  single task fails or is cancelled.
* Delegate messages for workflow and task cancellation. 
* The new `TSKTask` subclass `TSKSubworkflowTask` lets you run an entire workflow as a single task.
* Unit tests! We now have unit tests for all major functionality in the framework.

### Changes

* `TSKGraph` has been renamed to `TSKWorkflow` to more clearly express its purpose. All references
  to “graphs” have been replaced with references to “workflows.” To adapt to this change, we
  recommend you find & replace `graph` with `workflow` and `Graph` with `Workflow` for all your
  task-related code. This is what we did to make the change.
* Tasks no longer automatically start themselves after resetting. If you need to start a task after
  resetting it, send it the `‑start` message immediately after sending it `‑reset`.
* Retrying tasks that are in the pending or ready states no longer has any effect on the task itself,
  though the dependent tasks still receive the `‑retry` message. If you wish to run a task that is
  in the ready state, send it the `‑start` message. Tasks in the pending state cannot be run, but
  will automatically be started when their prerequisites finish successfully.
* As a minor optimization, sending `‑start` to a task only enqueues an operation on its operation 
  queue if the task is in the ready state. The operation itself still ensures that the task is in
  the ready state before invoking the task’s `‑main` method, but this should lead to better
  performance when a task’s operation queue has limited concurrency.


## Features

* Simple, well-documented Objective-C API
* Flexible system for expressing your app’s workflows in a clear, concise manner
* Powerful execution system that allows you to easily manage your workflow’s execution
    * Tasks are started as soon as all their prerequisites have finished successfully
    * Tasks that have no cross-dependencies are executed concurrently
    * Tasks and their dependents can be easily cancelled or retried
    * Tasks that previously finished successfully can be reset and re-run
* Strong task state reporting so that you know when a task succeeds, fails, or is cancelled
* Block and selector tasks for creating tasks that execute a block or method
* External condition tasks for representing prerequisite user interaction or other external
  conditions that must be fulfilled before work can continue
* Subworkflow tasks for executing whole workflows as a single step in a workflow
* Easy-to-extend API for creating your own reusable tasks
* Works with both iOS and OS X


## Installation

The easiest way to start using Task is to install it with CocoaPods.

```ruby
pod 'Task', '~> 1.0'
```

You can also build it and include the built products in your project. For OS X and iOS 8, just add
`Task.framework` to your project. For older versions of iOS, add Task’s public headers to your
header search path and link in `libTask.a`, all of which can be found in the project’s build output
directory.


## Using Task

The Task framework makes it easy to express your app’s workflows and manage the various tasks within
them. There are two types of objects in the framework: `TSKTasks` represent the individual steps in
a workflow, while `TSKWorkflows` represent the workflows themselves. Tasks are defined by the work
they do and their current state; workflows are defined by the tasks they contain and the
relationships between them. Tasks are not particularly useful without workflows. 

While `TSKTask` and `TSKWorkflow` seem similar to `NSOperation` and `NSOperationQueue`, they
represent very different concepts. Operations model *single executions* of work, with operation
queues controlling the order and concurrency of those executions. Operations don’t model the
concepts of success and failure, and they can’t be retried or re-run. Operations are essentially
transient: their usefulness ends as soon as they’re done executing.

Tasks, on the other hand, model *the concept* of work. Even after a task executes, its status can be
checked and it can be re-executed. The expectation is that you create tasks, start executing them at
the appropriate time, monitor their progress, and re-run or retry them as necessary. Workflows help
you to organize your work, providing a central object that describes the work that needs to be done
and the order it must be done in.


### Modeling Workflows

To model a workflow with Task, you first need to create a workflow object. Each workflow can be
initialized with a name — useful when debugging — and an operation queue on which the workflow’s
tasks run. If you don’t provide a queue, one will be created for you, which is what we do below: 

```objc
TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithName:@"Workflow"];
```

Once you’ve created a workflow, you need to create tasks that represent your work and add them to
your workflow. Each task is represented by a `TSKTask` instance. Before exploring the specifics of
the Task class hierarchy further, let’s look at how to create workflows with various task
configurations.

The simplest non-empty workflow contains a single task:

![Workflow with a single task](Resources/Example-A.png)

In this workflow, task *A* is the lone task, with no prerequisites. Creating it is trivial:

```objc
TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithName:@"Workflow A"];
TSKTask *taskA = …;
[workflow addTask:taskA prerequisites:nil];
```

When we’re ready to run the workflow, we can send it the `‑start` message. This will in turn start
`taskA`, and once it finishes successfully, the workflow will finish. We can make this workflow
slightly more complex by adding a second task *B*, which only runs if *A* finishes successfully.

![Workflow with two tasks in serial](Resources/Example-A%2BB.png)

Here, successful completion of *A* is a prerequisite to run *B*, presumably because *B* depends on
the result or some side-effect of running *A*. Modeling this workflow in code is straightforward:

```objc
TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithName:@"Workflow A+B"];
TSKTask *taskA = …;
TSKTask *taskB = …;
[workflow addTask:taskA prerequisites:nil];
[workflow addTask:taskB prerequisites:taskA, nil];
```

When executing this workflow, Task.framework will automatically run `taskA` first and start `taskB`
when `taskA` finishes successfully. But what if *B* didn’t depend on *A*? 

![Workflow with two tasks in parallel](Resources/Example-AB.png)

We need only change our code above so that *B* doesn’t list *A* as a prerequisite.

```objc
TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithName:@"Workflow AB"];
TSKTask *taskA = …;
TSKTask *taskB = …;
[workflow addTask:taskA prerequisites:nil];
[workflow addTask:taskB prerequisites:nil];
```

With this simple change, Task.framework will run `taskA` and `taskB` concurrently. Easy enough. Now,
suppose there’s some third task *C* that can only run when *A* and *B* are both done executing.

![Workflow with two tasks in parallel and a third that depends on both](Resources/Example-AB%2BC.png)

Again, this is simple to express:

```objc
TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithName:@"Workflow AB+C"];
TSKTask *taskA = …;
TSKTask *taskB = …;
TSKTask *taskC = …;
[workflow addTask:taskA prerequisites:nil];
[workflow addTask:taskB prerequisites:nil];
[workflow addTask:taskC prerequisites:taskA, taskB, nil];
```

When run, the workflow will automatically run tasks *A* and *B* concurrently, but only start *C*
after both *A* and *B* finish successfully. If either *A* or *B* fails, *C* won’t be run. If we 
changed our workflow so that *C* depended on *B*, but not *A*, we’d get a workflow that looks like
this:

![Workflow with two tasks in parallel and a third that depends on one](Resources/Example-A%28B%2BC%29.png)

By now, you can probably guess what our code would look like:

```objc
TSKWorkflow *workflow = [[TSKWorkflow alloc] initWithName:@"Workflow A(B+C)"];
TSKTask *taskA = …;
TSKTask *taskB = …;
TSKTask *taskC = …;
[workflow addTask:taskA prerequisites:nil];
[workflow addTask:taskB prerequisites:nil];
[workflow addTask:taskC prerequisites:taskB, nil];
```

Again, Task.framework manages the mechanics of executing tasks so that tasks are run with maximal
concurrency as soon as their prerequisite tasks have finished successfully. When building workflows,
you just tell the framework what tasks need to be run and what each task’s prerequisites are. Of 
course, the framework also needs to know what code should be executed when you run a task. Let’s 
take a look at that next.


### Creating Tasks

Every task is an instance of `TSKTask`, with its work being executed by the instance’s `‑main`
method. Unfortunately, `TSKTask` is an abstract class, so its `‑main` method doesn’t actually do
anything. To make a task that does real work, you either need to subclass `TSKTask` and override its
`‑main` method, or use one of its two built-in subclasses, `TSKBlockTask` and `TSKSelectorTask`. 

Subclassing makes sense if you need to repeatedly run tasks that perform the same type of work. For
example, if your app repeatedly breaks an image into multiple tiles and then processes those tiles
in the same way, you might create a `TSKTask` subclass called `ProcessImageTileTask` that can be
executed on each tile concurrently. Your subclass would override `‑main` to perform your work and,
if successful, invoke `‑finishWithResult:` on itself to indicate that the work was successful.
If you couldn’t complete the processing work due to some error, you would instead invoke
`‑failWithError:`.

```objc
@implementation ProcessImageTileTask

- (void)main
{
    // Process image data 
    NSError *error = nil;
    UIImage *result = [self processImageData:self.data rect:self.tileRect error:&error];

    // If the result is non-nil, finish successfully. Otherwise fail.
    if (result) {
        [self finishWithResult:result];
    } else {
        [self failWithError:error];
    }
}

…

@end
```

For smaller one-off tasks, you can use `TSKBlockTask`. `TSKBlockTask` instances execute a block to
perform their work. The block takes a single `TSKTask` parameter, to which you should send
`‑finishWithResult:` on success and `‑failWithError:` on failure. The block task below runs an
imaginary API request and invokes `‑finishWithResult:` and `‑failWithError:` in the API request’s
success and failure blocks, respectively.

```objc
TSKTask *requestTask = [[TSKBlockTask alloc] initWithName:@"API Request" block:^(TSKTask *task) { 
    [self executeAPIRequestWithSuccess:^(id response) {
        [task finishWithResult:response];
    } failure:^(NSError *error) {
        [task failWithError:error];
    }];
}];

[workflow addTask:Task prerequisites:requestTask, nil];

```

We can similarly create a task that performs a selector using `TSKSelectorTask`. The selector takes
a single `TSKTask` parameter. As you could probably guess, the method must invoke
`‑finishWithResult:` on success and `‑failWithError:` on failure. In the example below, we create
the selector task and set its prerequisite to `blockTask` from above. In our task method, we read
the prerequisite task’s result and use that as input for our work.

```objc
TSKTask *mappingTask = [[TSKSelectorTask alloc] initWithName:@"Map API Result"
                                                      target:self
                                                    selector:@selector(mapRequestResultWithTask:)];
                                                    
[workflow addTask:mappingTask prerequisites:requestTask, nil];

…

- (void)mapRequestResultWithTask:(TSKTask *)task
{
    NSDictionary *JSONResponse = [[task.prerequisites anyObject] result];
    NSManagedObject *mappedObject = [self mapJSONResponse:JSONResponse
                                              intoContext:self.managedObjectContext];

    NSError *error = nil;
    if ([self.managedObjectContext save:&error]) {
        [self finishWithResult:mappedObject.objectID];
    } else {
        [self failWithError:error];
    }
}
```
    
Again, the work that the task is actually doing is imaginary, but you get the idea.

There are two other built-in `TSKTask` subclasses: `TSKExternalConditionTask` and
`TSKSubworkflowTask`. Instances of the former do no real work, but instead gate progress in a
workflow until some external condition is fulfilled. This is ideal for tasks that require some user
input before being able to run. For example, suppose a REST API call requires user data as a
parameter. You could represent the API call as a `TSKTask`, and create an external condition task as
a prerequisite:

```objc
TSKExternalConditionTask *inputTask = [[TSKExternalConditionTask alloc] initWithName:@"Get input"];
[workflow addTask:inputTask prerequisites:nil];

TSKTask *requestTask = … ;
[workflow addTask:requestTask prerequisites:inputTask, nil];

…

// When the user has entered in their data
[dataTask fulfillWithResult:userSuppliedData];    
```

In this example, when the external condition task is fulfilled, the API request task automatically
starts.

`TSKSubworkflowTask` is a task that executes an entire workflow as its unit of work. This can be 
useful when composing complex workflows of several simpler ones:

```objc
TSKWorkflow *imageWorkflow = [[TSKWorkflow alloc] initWithName:@"Upload Image"];
TSKExternalConditionTask *imageAvailableTask = [[TSKExternalConditionTask alloc] init];
TSKWorkflow *filterWorkflow = [self workflowForImageFilter:filter];
TSKSubworkflowTask *filterTask = [[TSKSubworkflowTask alloc] initWithSubworkflow:filterWorkflow];
TSKTask *uploadImageTask = [[UploadDataTask alloc] init];

[imageWorkflow addTask:imageAvailableTask prerequisites:nil];
[imageWorkflow addTask:filterTask prerequisites:imageAvailableTask, nil];
[imageWorkflow addTask:uploadImageTask prerequisites:filterTask, nil];
```

### Changing the Execution State of Tasks

Once you have a task workflow set up, you can start executing it by sending the workflow the
`‑start` message. This will find all tasks in the workflow that have no prerequisite tasks and start
them. If you subsequently wish to cancel a task (or a whole workflow), you can send it the `‑cancel`
message. Retrying failed tasks is as simple as sending them the `‑retry` message, and if you wish to
reset a successfully finished task so that you can re-run it, send it the `‑reset` message. As
alluded to earlier, tasks propagate these messages down to their dependents, which propagate them to
their dependents, and so on, so that, e.g., cancelling a task also cancels all of its dependent
tasks.


### Being Notified of Task Completion, Failure, or Cancellation

Every task has an optional delegate that it can notify of success, failure, or cancellation. If
you’re interested in these events for an entire workflow, you can be a workflow’s delegate. Workflow
delegates receive messages when all the tasks in a workflow are complete and when a single task in a
workflow fails or is cancelled.


### More Info

Task.framework is fully documented, so if you’d like more information about how a class works, take
a look at the class header. Also, the `Example-iOS` subdirectory contains a fairly involved example
that includes a custom `TSKTask` subclass, external conditions, and task workflow delegate methods.
In particular, `‑[TaskViewController initializeWorkflow]` is a great place to experiment with your
own task workflow configurations, whose progress can be visualized by running the example app.


## Contributing, Filing Bugs, and Requesting Enhancements

If you would like to help fix bugs or add features to Task, send us a pull request!

We use GitHub issues for bugs, enhancement requests, and the limited support we provide, so open an
issue for any of those.


## License

All code is licensed under the MIT license. Do with it as you will.
