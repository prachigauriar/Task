//
//  WorkflowView.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import Foundation
import SwiftUI


struct WorkflowView<ViewModel> : View where ViewModel : WorkflowViewModeling {
    @ObservedObject var viewModel: ViewModel


    var body: some View {
        List(viewModel.taskViewModels) { (viewModel) in
            TaskView(viewModel: viewModel)
        }
#if !os(macOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .navigationTitle(viewModel.name)
        .alert(isPresented: $viewModel.isAlertPresented, viewModel.alertViewModel)
    }
}


extension View {
    @ViewBuilder
    func alert(isPresented: Binding<Bool>, _ alertViewModel: AlertViewModel?) -> some View {
        if let viewModel = alertViewModel {
            alert(Text(verbatim: viewModel.title), isPresented: isPresented) {
                ForEach(viewModel.actions) { (action) in
                    Button(action.label, role: action.role?.buttonRole, action: action.action)
                }
            } message: {
                Text(verbatim: viewModel.message)
            }
        } else {
            self
        }
    }
}
