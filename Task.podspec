Pod::Spec.new do |s|
  s.name         = "Task"
  s.version      = "1.2"

  s.summary      = <<-SUMMARY
                   A simple framework for expressing and executing your app’s workflows.
                   SUMMARY
  s.description  = <<-DESC
                   Task is a simple Cocoa framework for expressing and executing your application’s
                   workflows. Using Task, you need only express each step in your workflow — called
                   tasks — and what their prerequisite tasks are. After that, the framework handles
                   the mechanics of executing the steps in the correct order with the appropriate
                   level of concurrency, letting you know when tasks finish or fail. It also makes
                   it easy to cancel tasks, retry failed tasks, and re-run previously completed
                   tasks and workflows.
                   DESC

  s.author       = { "Ticketmaster" => "general@twotoasters.com" }
  s.homepage     = "https://github.com/Ticketmaster/Task"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/Ticketmaster/Task.git", :tag => s.version.to_s }

  s.source_files = 'Task/**/*.{h,m}'
end
