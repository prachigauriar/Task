//
//  TaskViewModeling.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import Foundation


@MainActor
protocol TaskViewModeling : Identifiable, ObservableObject where ID == ObjectIdentifier {
    var name: String { get }
    var state: TaskState { get }
    var stateText: String { get }
    var prerequisites: [TaskPrerequisiteViewModel] { get }

    var progress: Double { get }

    var actionText: String { get }
    var isActionDisabled: Bool { get }

    func performAction()
}


struct TaskPrerequisiteViewModel : Hashable, Identifiable {
    var name: String
    var state: TaskState


    var id: String {
        return name
    }
}


enum TaskState {
    case waiting
    case executing
    case canceled
    case finished
    case failed
}
