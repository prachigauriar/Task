//
//  TaskApp.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import SwiftUI


@main
@MainActor
struct TaskApp : App {
    let workflowViewModel = WorkflowViewModel.makeExample()


    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WorkflowView(viewModel: workflowViewModel)
            }
        }
    }
}
