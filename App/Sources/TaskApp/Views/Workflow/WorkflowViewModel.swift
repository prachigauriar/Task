//
//  WorkflowViewModel.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import Combine
import Foundation
import Task


final class WorkflowViewModel : WorkflowViewModeling {
    let workflow: TSKWorkflow
    let taskViewModels: [TaskViewModel]
    var subscribers: Set<AnyCancellable> = []


    @Published
    var alertViewModel: AlertViewModel?


    init(workflow: TSKWorkflow, tasks: [TSKTask]) {
        self.workflow = workflow
        self.taskViewModels = tasks.map(TaskViewModel.init(task:))

        workflow.notificationCenter.publisher(for: .TSKWorkflowDidFinish, object: workflow)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.workflowDidFinish()
            }
            .store(in: &subscribers)

        workflow.notificationCenter.publisher(for: .TSKWorkflowTaskDidFail, object: workflow)
            .receive(on: RunLoop.main)
            .compactMap { (notification) in
                notification.userInfo?[TSKWorkflowTaskKey] as? TSKTask
            }
            .sink { [weak self] (task) in
                self?.taskDidFail(task)
            }
            .store(in: &subscribers)
    }


    var name: String {
        return workflow.name
    }


    @MainActor
    func workflowDidFinish() {
        guard alertViewModel == nil else {
            return
        }

        alertViewModel = .init(
            title: "Tasks Finished",
            message: "All tasks finished successfully.",
            actions: []
        )
    }


    @MainActor
    func taskDidFail(_ task: TSKTask) {
        guard alertViewModel == nil //, task as? TSKExternalConditionTask == nil
        else {
            return
        }

        alertViewModel = .init(
            title: "Task Failed",
            message: "\(task.name ?? "Unknown task") failed.",
            actions: [
                .init(label: "Cancel", role: .cancel),
                .init(label: "Retry", action: task.retry),
            ]
        )
    }
}


extension WorkflowViewModel {
    static func makeExample() -> WorkflowViewModel {
        let workflow = TSKWorkflow(name: "Order Product Workflow")

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
        workflow.add(
            submitOrderTask,
            prerequisites: [
                uploadPhoto1Task,
                uploadPhoto2Task,
                metadataAvailableCondition
            ]
        )

        return .init(
            workflow: workflow,
            tasks: [
                createProjectTask,
                photo1AvailableCondition,
                uploadPhoto1Task,
                photo2AvailableCondition,
                uploadPhoto2Task,
                metadataAvailableCondition,
                submitOrderTask
            ]
        )
    }
}
