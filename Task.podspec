Pod::Spec.new do |s|
  s.name         = "Task"
  s.version      = "0.2"

  s.summary      = <<-SUMMARY
                   A simple Cocoa framework for representing interdependent units of work.
                   SUMMARY
  s.description  = <<-DESC
                   Task is a simple framework for representing tasks — units of work that have prerequisites,
                   dependencies, and can succeed or fail. The framework provides a straightforward way to 
                   create multiple tasks with blocks, selectors, etc.; create relationships between them; and
                   then execute them all together so that tasks only start once all their prerequisite tasks
                   finish successfully.
                   DESC

  s.author       = { "Two Toasters" => "general@twotoasters.com" }
  s.homepage     = "https://github.com/twotoasters/Task"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/twotoasters/Task.git", :tag => s.version.to_s }

  s.source_files = 'Task/**/*.{h,m}'
end
