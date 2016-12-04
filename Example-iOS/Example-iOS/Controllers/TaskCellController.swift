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
    static let finishedTaskText = UIColor(red: 0.37, green: 0.72, blue: 0.45, alpha: 1.0)
    static let failedTaskText = UIColor(red: 0.82, green: 0.01, blue: 0.11, alpha: 1.0)
    static let finishedTaskCellBackground = UIColor(red: 0.96, green: 1.0, blue: 0.95, alpha: 1.0)
    static let failedTaskCellBackground = UIColor(red: 1.0, green: 0.89, blue: 0.90, alpha: 1.0)

    static func cellBackgroundColor(for task: TSKTask) -> UIColor {
        if task.isFinished {
            return finishedTaskCellBackground
        } else if task.isFailed {
            return failedTaskCellBackground
        }

        return white
    }

    static func textColor(for task: TSKTask) -> UIColor {
        if task.isFinished {
            return finishedTaskText
        } else if task.isFailed {
            return failedTaskText
        }

        return black
    }
}


class TaskCellController {
    fileprivate(set) var task: TSKTask
    var cell: TaskTableViewCell?

    init(task: TSKTask) {
        self.task = task
    }


    func configure(_ cell: TaskTableViewCell) {
        cell.backgroundColor = UIColor.cellBackgroundColor(for: task)
        cell.nameLabel.text = task.name;
        cell.stateLabel.text = TSKTaskStateDescription(task.state);

        cell.progressView.progress = task.isFinished ? 1.0 : 0.0

        configurePrerequisiteLabel(cell.prerequisitesLabel)
        configureAction(for: cell.actionButton)
    }


    func configurePrerequisiteLabel(_ label: UILabel) {
        let sortedPrerequisites = task.prerequisiteTasks.sorted(by: { (task1, task2) -> Bool in
            return task1.name.localizedStandardCompare(task2.name).rawValue <= ComparisonResult.orderedSame.rawValue
        })

        guard !sortedPrerequisites.isEmpty else {
            label.text = "None"
            return
        }

        let newlineAttributedString = NSAttributedString(string: "\n")
        let attributedNames = NSMutableAttributedString()
        for (index, task) in sortedPrerequisites.enumerated() {
            let name = NSAttributedString(string: task.name, attributes: [NSForegroundColorAttributeName: UIColor.textColor(for: task)])

            attributedNames.append(name)
            if index != sortedPrerequisites.endIndex - 1 {
                attributedNames.append(newlineAttributedString)
            }
        }

        label.attributedText = attributedNames
    }


    fileprivate func configureAction(for button: UIButton) {
        button.removeTarget(nil, action: nil, for: .allTouchEvents)

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
                OperationQueue.main.addOperation {
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
            button.addTarget(self, action: #selector(fulfillCondition), for: .touchUpInside)
        } else {
            button.setTitle("Reset", for: .normal)
            button.addTarget(self, action: #selector(resetTask), for: .touchUpInside)
        }
    }


    @objc func fulfillCondition() {
        externalConditionTask.fulfill(withResult: nil)
    }
}
