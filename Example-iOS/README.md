# Task - Example-iOS

This is a somewhat thorough iOS example app that uses Task.framework to set up and execute work.


## Overview

The app’s UI centers around a table view that displays a list of tasks. Each table view cell
displays a task’s name, state, prerequisites, and progress. 

The tasks in the app are instances of one of two classes: `TSKExternalConditionTask` and
`TimeSlicedTask`. The former is part of the Task.framework. The latter is a demo subclass of
`TSKTask` which runs for a specified amount of time in little chunks. Unlike normal `TSKTasks`,
`TimeSlicedTasks` have a concept of progress. If you want to experiment, try changing some of the
tasks to use `TSKSelectorTask` or `TSKBlockTask`.

`TaskViewController` is the only view controller in the app. It creates the app’s tasks and task
graph in its `-initializeGraph` method. It also acts as the task graph’s delegate. Instances of
`TaskCellController` manage the individual task cells in the table. The task cells are instances of
`TaskTableViewCell`, which is built using a xib and a tiny amount of code to declare the cell’s
properties.

The code is commented and should be fairly straightforward. Be sure to open the app’s xcworkspace, not it’s xcodeproj.


## License

All code is licensed under the MIT license. Do with it as you will.
