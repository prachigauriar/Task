# Task.framework

Task is a simple Cocoa framework for representing tasks — units of work that can succeed or fail
— and their interrelationships. Using Task, you need only express each step in your workflow and
what its prerequisite steps are. After that, the framework handles the mechanics of executing the
steps in the correct order with the appropriate level of concurrency and letting you know when
tasks finish or fail. It also makes it easy to cancel tasks, retry failed tasks, and re-run
previously completed tasks.


## Features

* Simple, well-documented Objective-C API
* Flexible system for expressing your app’s workflows in a clear, concise manner
* Powerful execution system that allows you to easily manage your workflow’s execution
    * Tasks that are not waiting on their prerequisites are automatically started
    * Tasks that have no cross-dependencies are executed concurrently
    * Tasks and their dependents can be easily cancelled or retried
    * Tasks that previously finished successfully can be reset and re-run
* Strong task state reporting so that you know when a task succeeds or fails 
* Block and selector tasks for creating tasks that execute a block or method
* External condition tasks for representing prerequisite user interaction or some other external
  condition to be fulfilled
* Easy-to-extend API for creating your own reusable tasks
* Works with both iOS and OS X


## Installation

The easiest way to start using Task is to install it with CocoaPods.

    pod 'Task', '~> 0.3'

You can also build it and include the built products in your project. For OS X and iOS 8, just add
`Task.framework` to your project. For older versions of iOS, add Task’s public headers to your
header search path and link in `libTask.a`, all of which can be found in the project’s build output
directory.


## Using Task

The Task framework makes it easy to express your app’s workflows and manage the various tasks within
them. There are two types of objects in the Task framework: `TSKTasks` represent the individual
steps in a workflow, while `TSKGraphs` represent the workflows themselves. Tasks are defined by the  
work they do and their current state; graphs are defined by the tasks they contain and the 
relationships between them. Tasks are not particularly useful without graphs. 

While `TSKTask` and `TSKGraph` seem similar to `NSOperation` and `NSOperationQueue`, they represent
very different concepts. Operations model *single executions* of work, with operation queues
controlling the order and concurrency of those executions. Operations don’t model the concepts of
success and failure, and they can’t be retried or re-run. Operations are essentially transient:
their usefulness ends as soon as they’re done executing.

Tasks on the other hand model *the concept* of work. Even after a task executes, its status can be
checked and it can be re-executed. The expectation is that you can create them once, start executing
them at the appropriate time, monitor their progress, and re-run or retry tasks when appropriate.


### Modeling a Workflow

To model a workflow with Task, you first need to create a graph. Each graph can be initialized with
a name — useful when debugging — and an operation queue on which the graph’s tasks run. If you don’t
provide a queue, one will be created for you, which is what we do below: 

    TSKGraph *graph = [[TSKGraph alloc] initWithName:@"Workflow"];

Once you’ve created a graph, you need to create tasks that represent your work. `TSKTask` is an 
abstract class which means you can’t use it directly. For reusable tasks, you’ll probably want to 
subclass `TSKTask` and override its `‑main` method, but Task also includes two subclasses that can
be used to create tasks without subclassing. `TSKBlockTask` uses a block in place of its `‑main` 
method. When the block completes its work successfully, it should invoke `‑finishWithResult:` on its
task parameter. If the work failed, it should invoke `‑failWithError:` instead. The block task below 
invokes some imaginary API request and executes `‑finishWithResult:` and `‑failWithError:` in the 
API request’s success and failure blocks, respectively. We then add it to the task graph with no
prerequisites.

    TSKTask *blockTask = [[TSKBlockTask alloc] initWithName:@"Block Task" block:^(TSKTask *task) { 
        [self executeAPIRequestWithSuccess:^(id response) {
            [task finishWithResult:response];
        } failure:^(NSError *error) {
            [task failWithError:error];
        }];
    }];
    
    [graph addTask:blockTask prerequisites:nil];

We can also create a task that performs a selector using `TSKSelectorTask`. The selector takes a
single `TSKTask *` parameter. Like the block, the method should invoke `‑finishWithResult:` on
success and invoke `‑failWithError:` on failure. In the example below, we’ll make the selector task
and set its prerequisite to `blockTask` from above. In our task method, we’ll read the prerequisite
task’s result and use that as input for our work.

    TSKTask *selectorTask = [[TSKSelectorTask alloc] initWithName:@"Selector Task"
                                                           target:self
                                                         selector:@selector(mapResultFromTask:)];
    
    [graph addTask:selectorTask prerequisites:blockTask, nil];
    
    …
    
    - (void)mapResultFromTask:(TSKTask *)task
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
    
Again, the work that the task is actually doing is imaginary, but you get the idea.

Finally, there is a third built-in `TSKTask` subclass called `TSKExternalConditionTask`. Tasks
of this type do no real work, but instead gate progress in a graph until some external condition 
is fulfilled. This is ideal for tasks that require some user input before being able to run. For
example, suppose a REST API call requires user data as a parameter. You could represent the API 
call as a `TSKTask`, and create an external condition task as a prerequisite:

    TSKExternalConditionTask *dataTask = [[TSKExternalConditionTask alloc] initWithName:@"dataTask"];
    [graph addTask:dataTask prerequisites:nil];
    
    TSKTask *APIRequestTask = … ;
    [graph addTask:APIRequestTask prerequisites:dataTask, nil];
    
    …
    
    // When the user has entered in their data
    [dataTask fulfillWithResult:userSuppliedData];    

In this example, when the external condition task is fulfilled, the API task automatically starts.


### Changing the Execution State of Tasks

Once you have a task graph set up, you can very easily start executing it by sending the graph the
`‑start` message. This will find all tasks in the graph that have no prerequisite tasks and start
them. If you subsequently wish to cancel a task (or a whole graph), you can send it the `‑cancel`
message. Retrying failed tasks is as simple as sending them the `‑retry` message, and if you wish to
reset and re-run a successfully finished task, send it the `‑reset` message. As alluded to earlier,
tasks propagate these messages down to their dependents, which propagate them to their dependents,
and so on, so that, e.g., canceling a task also cancels all of its dependent tasks.


### Being Notified of Task Completion or Failure

Every task has an optional delegate that it can notify of success or failure. If you’re more
interested in the completion or failure of an entire graph, you can be a graph’s delegate. Graph
delegates receive messages when all the tasks in a graph are complete and when a single task in a
graph fails.


### More Info

Task.framework is fully documented, so if you’d like more information about how a class works, take
a look at the class header. Also, the `Example-iOS` subdirectory contains a fairly involved example
that includes a custom `TSKTask` subclass, external conditions, and task graph delegate methods. 
In particular, `‑[TaskViewController initializeGraph]` is a great place to experiment with your own
task graph configurations, whose progress can be visualized by running the example app.


## Contributing, Filing Bugs, and Requesting Enhancements

If you would like to help fix bugs or add features to Task, send us a pull request!

We use GitHub issues for bugs, enhancement requests, and the limited support we provide, so open an
issue for any of those.


## License

All code is licensed under the MIT license. Do with it as you will.
