//
//  TaskView.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import SwiftUI

struct TaskView<ViewModel> : View where ViewModel : TaskViewModeling {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ViewModel


    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.name)
                    .font(.headline)

                Spacer()

                Text(viewModel.stateText)
                    .font(.subheadline)

                viewModel.state.largeImage
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("Prerequisites")
                            .font(.subheadline)

                        VStack(alignment: .leading) {
                            if viewModel.prerequisites.isEmpty {
                                Text("None").font(.caption)
                            } else {
                                ForEach(viewModel.prerequisites) { (prerequisite) in
                                    HStack(alignment: .center, spacing: 4) {
                                        prerequisite.state.smallImage
                                        Text(prerequisite.name)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 24)
                    }
                }

                Spacer()

                Button(viewModel.actionText, action: viewModel.performAction)
                    .disabled(viewModel.isActionDisabled)
            }

            ProgressView(value: viewModel.progress)
        }
        .padding()
    }
}


extension TaskState {
    @ViewBuilder
    var smallImage: some View {
        switch self {
        case .waiting:
            Image(systemName: "clock")
                .foregroundColor(.gray)
        case .executing:
            Image(systemName: "figure.run.circle")
                .foregroundColor(.blue)
        case .canceled:
            Image(systemName: "questionmark.circle")
                .foregroundColor(.gray)
        case .finished:
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle")
                .symbolRenderingMode(.multicolor)
        }
    }


    @ViewBuilder
    var largeImage: some View {
        switch self {
        case .waiting:
            Image(systemName: "clock.fill")
                .foregroundColor(.gray)
        case .executing:
            Image(systemName: "figure.run.circle.fill")
                .foregroundColor(.blue)
        case .canceled:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.gray)
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.multicolor)
        }
    }
}


#Preview {
    List {
        TaskView(
            viewModel: PreviewTaskViewModel(
                name: "Task 1",
                state: .executing,
                stateText: "Executing",
                prerequisites: [
                    .init(name: "Prerequisite 1", state: .failed),
                    .init(name: "Prerequisite 2", state: .finished),
                    .init(name: "Prerequisite 3", state: .waiting),
                ],
                progress: 0.25,
                actionText: "Cancel",
                isActionDisabled: false
            )
        )

        TaskView(
            viewModel: PreviewTaskViewModel(
                name: "Task 2",
                state: .failed,
                stateText: "Failed",
                prerequisites: [
                    .init(name: "Prerequisite 1", state: .failed),
                    .init(name: "Prerequisite 2", state: .finished),
                    .init(name: "Prerequisite 3", state: .canceled),
                ],
                progress: 1,
                actionText: "Retry",
                isActionDisabled: false
            )
        )

        TaskView(
            viewModel: PreviewTaskViewModel(
                name: "Task 3",
                state: .finished,
                stateText: "Finished",
                prerequisites: [
                    .init(name: "Prerequisite 1", state: .failed),
                    .init(name: "Prerequisite 2", state: .finished),
                    .init(name: "Prerequisite 3", state: .executing),
                ],
                progress: 1,
                actionText: "Reset",
                isActionDisabled: false
            )
        )
    }
    #if !os(macOS)
    .listStyle(.insetGrouped)
    #endif
}


final class PreviewTaskViewModel : TaskViewModeling {
    var name: String
    var state: TaskState
    var stateText: String
    var prerequisites: [TaskPrerequisiteViewModel]

    var progress: Double

    var actionText: String
    var isActionDisabled: Bool

    init(
        name: String,
        state: TaskState,
        stateText: String,
        prerequisites: [TaskPrerequisiteViewModel],
        progress: Double,
        actionText: String,
        isActionDisabled: Bool
    ) {
        self.name = name
        self.state = state
        self.stateText = stateText
        self.prerequisites = prerequisites
        self.progress = progress
        self.actionText = actionText
        self.isActionDisabled = isActionDisabled
    }


    func performAction() {
        // Intentionally empty
    }
}
