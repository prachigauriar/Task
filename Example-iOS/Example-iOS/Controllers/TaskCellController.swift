//
//  TaskCellController.swift
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


fileprivate extension UIColor {
    static let finishedTaskCellBackground = UIColor(red: 0.96, green: 1.0, blue: 0.95, alpha: 1.0)
    static let failedTaskCellBackground = UIColor(red: 1.0, green: 0.89, blue: 0.90, alpha: 1.0)
}


class TaskCellController {
    fileprivate(set) var task: TSKTask
    var cell: TaskTableViewCell?

    init(task: TSKTask) {
        self.task = task
    }


    func configure(_ cell: TaskTableViewCell) {
        if task.isFinished {
            cell.backgroundColor = UIColor.finishedTaskCellBackground
        } else if task.isFailed {
            cell.backgroundColor = UIColor.failedTaskCellBackground
        } else {
            cell.backgroundColor = UIColor.white
        }

        // Set the cell’s name, state, prerequisite labels, and progress
        cell.nameLabel.text = task.name;
        cell.stateLabel.text = TSKTaskStateDescription(task.state);

        let prerequisiteNames = task.prerequisiteTasks.map { $0.name }.sorted()
        cell.prerequisitesLabel.text = prerequisiteNames.isEmpty ? "None" : prerequisiteNames.joined(separator: "\n")

        cell.progressView.progress = task.isFinished ? 1.0 : 0.0

        // Button configuration is complicated…
        configureAction(for: cell.actionButton)
    }


    fileprivate func configureAction(for button: UIButton) {
        // Get rid of any existing targets
        button.removeTarget(nil, action: nil, for: .allTouchEvents)

        // Otherwise, we can start, cancel, retry, or reset the tasks
        switch task.state {
        case .pending:
            button.setTitle("N/A", for: .normal)
            button.isEnabled = false
        case .ready:
            button.setTitle("Start", for: .normal)
            button.isEnabled = true
            button.addTarget(self, action: #selector(startTask), for: .touchUpInside)
        case .executing:
            button.setTitle("Cancel", for: .normal)
            button.isEnabled = true
            button.addTarget(self, action: #selector(cancelTask), for: .touchUpInside)
        case .cancelled, .failed:
            button.setTitle("Retry", for: .normal)
            button.isEnabled = true
            button.addTarget(self, action: #selector(retryTask), for: .touchUpInside)
        case .finished:
            button.setTitle("Reset", for: .normal)
            button.isEnabled = true
            button.addTarget(self, action: #selector(resetTask), for: .touchUpInside)
        }
    }


    @objc func startTask() {
        task.start()
    }


    @objc func cancelTask() {
        task.cancel()
    }


    @objc func retryTask() {
        task.retry()
    }


    @objc func resetTask() {
        task.reset()
    }
}


class TimeSlicedTaskCellController: TaskCellController {
    var timeSlicedTask: TimeSlicedTask {
        return task as! TimeSlicedTask
    }


    init(task: TimeSlicedTask) {
        super.init(task: task)
    }


    override func configure(_ cell: TaskTableViewCell) {
        super.configure(cell)
        cell.progressView.progress = Float(timeSlicedTask.progress)
    }


    override var cell: TaskTableViewCell? {
        didSet {
            guard let cell = cell else {
                timeSlicedTask.progressBlock = nil
                return
            }

            timeSlicedTask.progressBlock = { (task: TimeSlicedTask) in
                DispatchQueue.main.async {
                    cell.progressView.setProgress(Float(task.progress), animated: true)
                }
            }
        }
    }
}


class ExternalConditionTaskCellController: TaskCellController {
    var externalConditionTask: TSKExternalConditionTask {
        return task as! TSKExternalConditionTask
    }


    init(task: TSKExternalConditionTask) {
        super.init(task: task)
    }


    override func configureAction(for button: UIButton) {
        button.isEnabled = true

        if !externalConditionTask.isFulfilled {
            button.setTitle("Fulfill", for: .normal)
            button.addTarget(self, action: #selector(fulfillConditionTask), for: .touchUpInside)
        } else {
            button.setTitle("Reset", for: .normal)
            button.addTarget(self, action: #selector(resetTask), for: .touchUpInside)
        }
    }


    @objc func fulfillConditionTask() {
        externalConditionTask.fulfill(withResult: nil)
    }
}
