# Task.framework

Task is a simple Cocoa framework for expressing and executing your application’s workflows. Using
Task, you need only express each step in your workflow — called tasks — and what their prerequisite
tasks are. After that, the framework handles the mechanics of executing the steps in the correct
order with the appropriate level of concurrency, letting you know when tasks finish or fail. It also
makes it easy to cancel tasks, retry failed tasks, and re-run previously completed tasks and
workflows.


## Features

* Simple, well-documented API that is at home in both Swift and Objective-C
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
* Works with all of Apple’s platforms


## What’s New in 1.1

Task 1.1 is a significant update that makes it easier for Task subclasses to get prerequisite
results and respond to state changes. It also contains a very important fix related to task
resetting. Users are strongly encouraged to upgrade to Task 1.1.


### Keyed Prerequisites

When adding a task to a workflow, prerequisites can be given unique keys that can be used to
retrieve their results. For example,

```swift
let workflow: TSKWorkflow = …
let taskA: TSKTask = …
let taskB: TSKTask = …
let taskC: TSKTask = …

…

workflow.add(taskC, keyedPrerequisiteTasks: ["userTask": taskA, "projectTask": taskB])
```

Later, `taskC` can access the results of `taskA` and `taskB`, e.g., in its `main()` method, using
`TSKTask.prerequisiteResult(forKey:)`:

```swift
override func main() { 
{
    guard let user = prerequisiteResult(forKey: userTask) as? User,
        let project = prerequisiteResult(forKey: projectTask) as? Project else {
        …
    }

    …
}
```

Tasks can even specify which keys they require to run by overriding `requiredPrerequisiteKeys()`. If
this requirement is not fulfilled when a task is added to a workflow, an assertion is raised.


### Task Subclass Interface

We’ve also added numerous methods to `TSKTask` so that subclasses can respond to changes in task 
state:
 
* `didCancel()`
* `didReset()`
* `didRetry()`
* `didFinish(with:)` (`didFinishWithResult:` in Objective-C)
* `didFail(with:)` (`didFailWithError:` in Objective-C)

While the default implementations of these methods do nothing, subclasses can override them to
perform necessary actions upon state changes. This should obviate the need for `TSKTask` subclasses
to observe notifications posted by their superclass.


### Reset Bug Fix

Task 1.0 contains a serious bug in which a reset task may be able to run even if its prerequisites
have not all completed. This bug can be reproduced as follows:

1. Set up a workflow with two tasks, A and B, with A listed as a prerequisite of B.
2. Run the workflow to completion.
3. Reset B. A is now in the Finished state. B should be Ready.
4. Reset A. A is now in the Ready state. As such, B should be in the Pending state.

In Task 1.0, B will be in the Ready state. Task 1.1 fixes this.


## Installation

The easiest way to start using Task is to install it with CocoaPods.

```ruby
pod 'Task', '~> 1.1'
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

```swift
let workflow = TSKWorkflow(name:"Workflow")
```

Once you’ve created a workflow, you need to create tasks that represent your work and add them to
your workflow. Each task is represented by a `TSKTask` instance. Before exploring the specifics of
the Task class hierarchy further, let’s look at how to create workflows with various task
configurations.

The simplest non-empty workflow contains a single task:

```
┌───────────┐        ╔═══════════╗        ┌──────────┐
│   Start   │───────>║     A     ║───────>│  Finish  │
└───────────┘        ╚═══════════╝        └──────────┘
```

In this workflow, task *A* is the lone task, with no prerequisites. Creating it is trivial:

```swift
let workflow = TSKWorkflow("Workflow A")
let taskA: TSKTask = …
workflow.add(taskA, prerequisiteTasks: nil)
```

When we’re ready to run the workflow, we can send it the `‑start` message. This will in turn start
`taskA`, and once it finishes successfully, the workflow will finish. We can make this workflow
slightly more complex by adding a second task *B*, which only runs if *A* finishes successfully.

```
┌───────────┐        ╔═══════════╗        ╔═══════════╗        ┌──────────┐
│   Start   │───────>║     A     ║───────>║     B     ║───────>│  Finish  │
└───────────┘        ╚═══════════╝        ╚═══════════╝        └──────────┘
```

Here, successful completion of *A* is a prerequisite to run *B*, presumably because *B* depends on
the result or some side-effect of running *A*. Modeling this workflow in code is straightforward:

```swift
let workflow = TSKWorkflow("Workflow A+B")
let taskA: TSKTask = …
let taskB: TSKTask = …
workflow.add(taskA, prerequisiteTasks: nil)
workflow.add(taskB, prerequisiteTasks: [taskA])
```

When executing this workflow, Task.framework will automatically run `taskA` first and start `taskB`
when `taskA` finishes successfully. But what if *B* didn’t depend on *A*? 

```
                     ╔═══════════╗                   
                ┌───>║     A     ║───┐               
                │    ╚═══════════╝   │               
┌───────────┐   │                    │    ┌──────────┐
│   Start   │───┤                    ├───>│  Finish  │
└───────────┘   │                    │    └──────────┘
                │    ╔═══════════╗   │               
                └───>║     B     ║───┘               
                     ╚═══════════╝                   
```

We need only change our code above so that *B* doesn’t list *A* as a prerequisite.

```swift
let workflow = TSKWorkflow("Workflow AB")
let taskA: TSKTask = …
let taskB: TSKTask = …
workflow.add(taskA, prerequisiteTasks: nil)
workflow.add(taskB, prerequisiteTasks: nil)
```

With this simple change, Task.framework will run `taskA` and `taskB` concurrently. Easy enough. Now,
suppose there’s some third task *C* that can only run when *A* and *B* are both done executing.

```
                    ╔═══════════╗                                       
                ┌──>║     A     ║───┐                                   
                │   ╚═══════════╝   │                                   
┌───────────┐   │                   │   ╔═══════════╗       ┌──────────┐
│   Start   │───┤                   ├──>║     C     ║──────>│  Finish  │
└───────────┘   │                   │   ╚═══════════╝       └──────────┘
                │   ╔═══════════╗   │                                   
                └──>║     B     ║───┘                                   
                    ╚═══════════╝                                       
```

Again, this is simple to express:

```swift
let workflow = TSKWorkflow("Workflow AB+C")
let taskA: TSKTask = …
let taskB: TSKTask = …
let taskC: TSKTask = …
workflow.add(taskA, prerequisiteTasks: nil)
workflow.add(taskB, prerequisiteTasks: nil)
workflow.add(taskC, prerequisiteTasks: [taskA, taskB])
```

When run, the workflow will automatically run tasks *A* and *B* concurrently, but only start *C*
after both *A* and *B* finish successfully. If either *A* or *B* fails, *C* won’t be run. If we 
changed our workflow so that *C* depended on *B*, but not *A*, we’d get a workflow that looks like
this:

```
                              ╔═══════════╗                             
                ┌────────────>║     A     ║─────────────┐               
                │             ╚═══════════╝             │               
┌───────────┐   │                                       │   ┌──────────┐
│   Start   │───┤                                       ├──>│  Finish  │
└───────────┘   │                                       │   └──────────┘
                │   ╔═══════════╗       ╔═══════════╗   │               
                └──>║     B     ║──────>║     C     ║───┘               
                    ╚═══════════╝       ╚═══════════╝                   
```

By now, you can probably guess what our code would look like:

```swift
let workflow = TSKWorkflow("Workflow A(B+C)")
let taskA: TSKTask = …
let taskB: TSKTask = …
let taskC: TSKTask = …
workflow.add(taskA, prerequisiteTasks: nil)
workflow.add(taskB, prerequisiteTasks: nil)
workflow.add(taskC, prerequisiteTasks: [taskB])
```

Again, Task.framework manages the mechanics of executing tasks so that tasks are run with maximal
concurrency as soon as their prerequisite tasks have finished successfully. When building workflows,
you just tell the framework what tasks need to be run and what each task’s prerequisites are. Of 
course, the framework also needs to know what code should be executed when you run a task. Let’s 
take a look at that next.


### Creating Tasks

Every task is an instance of `TSKTask`, with its work being executed by the instance’s `main()`
method. Unfortunately, `TSKTask` is an abstract class, so its `main()` method doesn’t actually do
anything. To make a task that does real work, you either need to subclass `TSKTask` and override its
`main()` method, or use `TSKBlockTask` and `TSKSelectorTask`, which allow you to wrap a block or
method invocation in a task, respectively.

Subclassing makes sense if you need to repeatedly run tasks that perform the same type of work. For
example, if your app repeatedly breaks an image into multiple tiles and then processes those tiles
in the same way, you might create a `TSKTask` subclass called `ProcessImageTileTask` that can be
executed on each tile concurrently. Your subclass would override `main()` to perform your work and,
if successful, invoke `finish(with:)` on itself to indicate that the work was successful. If you
couldn’t complete the processing work due to some error, you would instead invoke `fail(with:)`.

```swift
class ProcessImageTileTask : TSKTask {
    override func main() {
        do {
            // Process image data 
            let result = try process(imageData, rect: tileRect)
            finish(with: result)
        } catch {
            fail(with: error)
        }
    }

    …
}
```

For smaller one-off tasks, you can use `TSKBlockTask`. `TSKBlockTask` instances execute a block to
perform their work. The block takes a single `TSKTask` parameter, to which you should send
`finish(with:)` on success and `fail(with:)` on failure. The block task below runs an imaginary API
request and invokes `finish(with:)` and `fail(with:)` in the API request’s success and failure
blocks, respectively.

```swift
func setUpWorkflow() {
    …

    let blockTask = TSKBlockTask(name: "API Request") { [weak self] task in 
        weak?.execute(request, success: { response in 
            task.finish(with: response)
        }, failure: { error in
            task.fail(with: error)
        })
    }

    workflow.add(blockTask, prerequisiteTasks: [requestTask])
    
    …
}
```

We can similarly create a task that performs a selector using `TSKSelectorTask`. The selector takes
a single `TSKTask` parameter. As you could probably guess, the method must invoke `finish(with:)` on
success and `fail(with:)` on failure. In the example below, we create the selector task and set its
prerequisite to `blockTask` from above. In our task method, we read the prerequisite task’s result
and use that as input for our work.

```swift
func setUpWorkflow() {
    …
    
    let mappingTask TSKSelectorTask(name: "Map API Result", 
                                    target: self, 
                                    selector: #selector(mapRequestResult(with:)))
                                                    
    workflow.add(mappingTask, prerequisiteTasks: [requestTask])

    …
}

…

@objc func mapRequestResult(with task: TSKTask) {
    guard let jsonResponse = task.anyPrerequisiteResult as? [String:Any] else {
        fail(with: …)
        return
    }
    
    do {
        let mappedObjectID = try map(jsonResponse, into: managedObjectContext)
        finish(with: mappedObjectID)
    } catch {
        fail(with: error)
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

```swift
let inputTask = TSKExternalConditionTask(name: "Get input")
workflow.add(inputTask, prerequisiteTasks: nil)

let requestTask: TSKTask = … 
workflow.add(requestTask, prerequisiteTasks: [inputTask])

…

// When the user has entered in their input
inputTask.fulfill(with: userSuppliedData)
```

In this example, when the external condition task is fulfilled, the API request task automatically
starts.

`TSKSubworkflowTask` is a task that executes an entire workflow as its unit of work. This can be 
useful when composing complex workflows of several simpler ones:

```swift
let imageWorkflow = TSKWorkflow(name: "Upload Image")
let imageAvailableTask = TSKExternalConditionTask()
let filterWorkflow = workflow(for: imagefilter)
let filterTask = TSKSubworkflowTask(subworkflow: filterWorkflow)
let uploadImageTask = UploadDataTask()

imageWorkflow.add(imageAvailableTask, prerequisiteTasks: nil)
imageWorkflow.add(filterTask, prerequisitesTasks: [imageAvailableTask])
imageWorkflow.add(uploadImageTask, prerequisiteTasks: [filterTask])
```


### Getting Results from Prerequisite Tasks

When tasks finish successfully, they can finish with a result — an object that represents the final
result of their work. Quite commonly, tasks use the results of their prerequisite tasks to perform
additional work. For example, a workflow for executing a RESTful API call might include a task that 
sends an HTTP request and converts the response bytes into JSON, followed by a task that maps the 
first task’s resulting JSON object into a model object. Task.framework provides numerous methods for
accessing a task’s prerequisite results.

In the simplest case, a task doesn’t use its prerequisites’ results at all; the task simply runs its
`main()` method with no dependency on its prerequisites’ output. A very slightly more complex case
occurs when a task has only one prerequisite and depends on its result. In this case, the task can
simply invoke `anyPrerequisiteResult()` on itself to get the result of one of its prerequisites.
Since the task has only one prerequisite, this is equivalent to getting the result of that single
prerequisite.

A task may also aggregate the results of its prerequisites uniformly. For example, a workflow might
break some data set into chunks, process each of those chunks in separate tasks, and then combine
the results of those tasks in a final task. In cases like these, a task can invoke
`allPrerequisiteResults()` on itself to get an array of all its prerequisite results and process
them uniformly.

Sometimes, tasks need to use the results of multiple prerequisite in varied ways. For this purpose,
Task.framework has the concept of *keyed* prerequisites. Keyed prerequisites allow a task to assign
unique keys to its prerequisites with which they can be referred later. Tasks can define their keyed
prerequisites using `TSKWorkflow.add(_:keyedPrerequisiteTasks:)` or 
`TSKWorkflow.add(_:prerequisiteTasks:keyedPrerequisiteTasks:)`. In both cases, the
`keyedPrerequisiteTasks` parameter is a dictionary that maps a key to its associated task. The
result of a given keyed prerequisite can be retrieved by sending a task
`prerequisiteResult(forKey:)`. 

For example, suppose a task were added to a workflow as follows:

```swift
workflow.add(task, keyedPrerequisiteTasks: ["userTask": task1, "addressTask": task2])
```

The task can easily refer to the results of `task1` and `task2`, e.g., in its `main()` method like so:

```swift
override func main() {
    guard let user = prerequisiteResult(forKey: "userTask") as? User, 
        let address = prerequisiteResult(forKey: "addressTask") as? Address else {
        …        
    }

    user.address = address
    
    …
}
```

Furthermore, if a task cannot function without certain keyed prerequisites, it can specify that to
Task.framework by overriding `requiredPrerequisiteKeys()`. The `TSKTask` subclass in our example
above might override that method as follows:

```swift
override func requiredPrerequisiteKeys() -> Set<AnyHashable> {
    return ["userTask", "addressTask"]
}
```

If subclasses override this method and return a non-empty set, `TSKWorkflow` will ensure that the
required prerequisite keys have corresponding tasks when the task is added to a workflow. For
convenience, `TSKBlockTask` and `TSKSelectorTask` can have their required prerequisite keys set
during initialization. 


### Changing the Execution State of Tasks

Once you have a task workflow set up, you can start executing it by sending the workflow the
`start()` message. This will find all tasks in the workflow that have no prerequisite tasks and start
them. If you subsequently wish to cancel a task (or a whole workflow), you can send it the `cancel()`
message. Retrying failed tasks is as simple as sending them the `retry()` message, and if you wish to
reset a successfully finished task so that you can re-run it, send it the `reset()` message. As
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
In particular, `WorkflowViewController.initializeWorkflow()` is a great place to experiment with your
own task workflow configurations, whose progress can be visualized by running the example app.


## Contributing, Filing Bugs, and Requesting Enhancements

If you would like to help fix bugs or add features to Task, send us a pull request!

We use GitHub issues for bugs, enhancement requests, and the limited support we provide, so open an
issue for any of those.


## License

All code is licensed under the MIT license. Do with it as you will.
