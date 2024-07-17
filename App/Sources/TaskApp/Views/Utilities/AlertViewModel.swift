//
//  AlertViewModel.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/5/24.
//

import Foundation
import SwiftUI


struct AlertViewModel {
    struct ActionViewModel : Identifiable {
        enum Role {
            case destructive
            case cancel
        }


        var label: String
        var role: Role?
        var action: () -> Void = { }


        var id: String {
            label
        }
    }


    var title: String
    var message: String
    var actions: [ActionViewModel]
}


protocol AlertViewModelPresenting : ObservableObject {
    var isAlertPresented: Bool { get set }
    var alertViewModel: AlertViewModel? { get set }
}


extension AlertViewModelPresenting {
    var isAlertPresented: Bool {
        get {
            alertViewModel != nil
        }

        set {
            precondition(!newValue, "isAlertPresented cannot be set to true")
            alertViewModel = nil
        }
    }


    var alertTitle: String {
        return alertViewModel?.title ?? ""
    }


    var messageText: String {
        return alertViewModel?.message ?? ""
    }
}


extension AlertViewModel.ActionViewModel.Role {
    var buttonRole: ButtonRole {
        switch self {
        case .destructive:
            return .destructive
        case .cancel:
            return .cancel
        }
    }
}
