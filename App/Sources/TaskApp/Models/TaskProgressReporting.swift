//
//  TaskProgressReporting.swift
//  TaskApp
//
//  Created by Prachi Gauriar on 7/7/24.
//

import Foundation
import Task


@objc
protocol TaskProgressReporting {
    var progress: Double { get }
}


extension TSKTask : TaskProgressReporting {
    var progress: Double {
        return isFinished ? 1 : 0
    }
}
