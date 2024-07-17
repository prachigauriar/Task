//
//  WorkflowViewModeling.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import Foundation


@MainActor
protocol WorkflowViewModeling : ObservableObject, AlertViewModelPresenting {
    associatedtype SomeTaskViewModel : TaskViewModeling

    var name: String { get }
    var taskViewModels: [SomeTaskViewModel] { get }
}
