//
//  WorkflowViewController.swift
//  Example-iOS
//
//  Created by Prachi Gauriar on 8/28/2016.
//  Copyright © 2016 Ticketmaster Entertainment, Inc. All rights reserved.
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

import Task
import UIKit


class WorkflowViewController : UIViewController, TSKWorkflowDelegate, UITableViewDataSource, UITableViewDelegate {
    private static let kTaskCellReuseIdentifier = "TSKTaskViewController.TaskCell"

    private let workflow: TSKWorkflow = TSKWorkflow(name: "Order Product Workflow")
    private var tasks: [TSKTask] = []
    private var taskStateObservers: [KeyValueObserver<TSKTask>] = []
    private var cellControllers: [TaskCellController] = []

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = workflow.name
        initializeWorkflow()

        // Create a cell controller for each task
        cellControllers = tasks.map { (task: TSKTask) -> TaskCellController in
            switch task {
            case let task as TimeSlicedTask:
                return TimeSlicedTaskCellController(task: task)
            case let task as TSKExternalConditionTask:
                return ExternalConditionTaskCellController(task: task)
            default:
                return TaskCellController(task: task)
            }
        }

        // Create the task state observers after the cell controllers, since the task state observer
        // will update the cell
        taskStateObservers = tasks.map { (task: TSKTask) -> KeyValueObserver<TSKTask> in
            KeyValueObserver(object: task, keyPath: #keyPath(TSKTask.state)) { [unowned self] (task) in
                OperationQueue.main.addOperation {
                    self.updateCell(for: task)

                    for dependentTask in task.dependentTasks {
                        self.updateCell(for: dependentTask)
                    }
                }
            }
        }

        // Set up our table view
        tableView.register(TaskTableViewCell.nib, forCellReuseIdentifier: WorkflowViewController.kTaskCellReuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
    }


    func initializeWorkflow() {
        workflow.delegate = self

        // This task is completely independent of other tasks. Imagine that this creates a server resource that
        // we are going to update with additional data
        let createProjectTask = TimeSlicedTask(name: "Create Project", timeRequired: 2.0)
        createProjectTask.probabilityOfFailure = 0.1;
        workflow.add(createProjectTask, prerequisites: nil)

        // This is an external condition task that indicates that a photo is available. Imagine that this is
        // fulfilled when the user takes a photo or chooses a photo from their library for this project.
        let photo1AvailableCondition = TSKExternalConditionTask(name: "Photo 1 Available")
        workflow.add(photo1AvailableCondition, prerequisites: nil)

        // This uploads the first photo. It can’t run until the project is created and the photo is available
        let uploadPhoto1Task = TimeSlicedTask(name: "Upload Photo 1", timeRequired: 5.0)
        uploadPhoto1Task.probabilityOfFailure = 0.15;
        workflow.add(uploadPhoto1Task, prerequisites: [createProjectTask, photo1AvailableCondition]);

        // These are analagous to the previous two tasks, but for a second photo
        let photo2AvailableCondition = TSKExternalConditionTask(name: "Photo 2 Available")
        let uploadPhoto2Task = TimeSlicedTask(name: "Upload Photo 2", timeRequired: 6.0)
        uploadPhoto2Task.probabilityOfFailure = 0.15;

        workflow.add(photo2AvailableCondition, prerequisites: nil)
        workflow.add(uploadPhoto2Task, prerequisites: [createProjectTask, photo2AvailableCondition])

        // This is an external condition task that indicates that some metadata has been entered. Imagine that
        // once the two photos are uploaded, the user is asked to name the project.
        let metadataAvailableCondition = TSKExternalConditionTask(name: "Metadata Available")
        workflow.add(metadataAvailableCondition, prerequisites: nil)

        // This submits an order. It can’t run until the photos are uploaded and the metadata is provided.
        let submitOrderTask = TimeSlicedTask(name: "Submit Order", timeRequired: 2.0)
        submitOrderTask.probabilityOfFailure = 0.1;
        workflow.add(submitOrderTask, prerequisites: [uploadPhoto1Task, uploadPhoto2Task, metadataAvailableCondition])

        tasks = [createProjectTask,
                 photo1AvailableCondition, uploadPhoto1Task,
                 photo2AvailableCondition, uploadPhoto2Task,
                 metadataAvailableCondition,
                 submitOrderTask]
    }


    func updateCell(for task: TSKTask) {
        guard let index = tasks.index(of: task) else {
            return
        }

        let cellController = cellControllers[index]
        guard let cell = cellController.cell else {
            return
        }

        cellController.configure(cell)
    }


    // MARK: - Table view data source and delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellControllers.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkflowViewController.kTaskCellReuseIdentifier, for: indexPath) as! TaskTableViewCell
        let controller = self.cellControllers[indexPath.row];
        controller.cell = cell;
        controller.configure(cell)
        return cell;
    }


    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellControllers[indexPath.row].cell = nil
    }


    // MARK: - Workflow delegate

    func workflowDidFinish(_ workflow: TSKWorkflow) {
        OperationQueue.main.addOperation {
            let alertController = UIAlertController(title: "Tasks Finished", message: "All tasks finished successfully.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }


    func workflow(_ workflow: TSKWorkflow, task: TSKTask, didFailWithError error: Error?) {
        guard task as? TSKExternalConditionTask == nil else {
            return
        }

        OperationQueue.main.addOperation {
            let alertController = UIAlertController(title: "Task Failed", message: "\(task.name ?? "Unknown task") failed.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Retry", style: .default) { [task] (_) in
                task.retry()
            })
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
