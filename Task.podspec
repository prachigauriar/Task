Pod::Spec.new do |s|
  s.name         = "Task"
  s.version      = "0.1"

  s.summary      = <<-SUMMARY
                   A simple Cocoa framework for representing tasks — units of work that have prerequisites,
                   dependencies, and can succeed or fail.
                   SUMMARY
  s.description  = <<-DESC
                   TWTValidation is a Cocoa framework for declaratively validating data. It provides a
                   mechanism for validating individual objects and collections, and for combining multiple
                   validators using logical operators to create more complex validations."
                   DESC

  s.author       = { "Two Toasters" => "general@twotoasters.com" }
  s.homepage     = "https://github.com/twotoasters/Task"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/twotoasters/Task.git", :tag => s.version.to_s }

  s.source_files = 'Task/**/*.{h,m}'
end
