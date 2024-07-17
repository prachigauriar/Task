//
//  TaskViewModel.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import Combine
import Foundation
import Task


final class TaskViewModel : TaskViewModeling {
    let task: TSKTask
    private var taskChangeSubscribers: [AnyCancellable] = []


    init(task: TSKTask) {
        self.task = task

        for task in task.prerequisiteTasks + [task] {
            task.publisher(for: \.state)
                .map { _ in return () }
                .merge(with: task.publisher(for: \.progress).map { _ in return () })
                .receive(on: RunLoop.main)
                .sink { [weak self] (_) in
                    self?.objectWillChange.send()
                }
                .store(in: &taskChangeSubscribers)
        }
    }


    var name: String {
        task.name
    }


    var state: TaskState {
        TaskState(tskTaskState: task.state)
    }


    var stateText: String {
        TSKTaskStateDescription(task.state) ?? ""
    }


    var prerequisites: [TaskPrerequisiteViewModel] {
        task.prerequisiteTasks
            .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
            .map { (task) in
                return .init(name: task.name, state: .init(tskTaskState: task.state))
            }
    }


    var progress: Double {
        return task.progress
    }


    var actionText: String {
        switch task.state {
        case .ready:
            return task is TSKExternalConditionTask ? "Fulfill" : "Start"
        case .executing:
            return "Cancel"
        case .cancelled, .failed:
            return "Retry"
        case .finished:
            return "Reset"
        default:
            return "N/A"
        }
    }


    var isActionDisabled: Bool {
        return task.state == .pending
    }


    func performAction() {
        switch task.state {
        case .ready:
            if let task = task as? TSKExternalConditionTask {
                task.fulfill(with: nil)
            } else {
                task.start()
            }
        case .executing:
            task.cancel()
        case .cancelled, .failed:
            task.retry()
        case .finished:
            task.reset()
        default:
            return
        }
    }
}


extension TaskState {
    init(tskTaskState: TSKTaskState) {
        switch tskTaskState {
        case .pending, .ready:
            self = .waiting
        case .executing:
            self = .executing
        case .cancelled:
            self = .canceled
        case .failed:
            self = .failed
        case .finished:
            self = .finished
        default:
            self = .waiting
        }
    }
}
