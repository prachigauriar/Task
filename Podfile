source 'https://github.com/CocoaPods/Specs.git'

Target = Struct.new(:target, :platform, :platform_version)

targets = [ Target.new('Task', :osx, '10.8'), 
            Target.new('Task-iOS', :ios, '6.0'), 
            Target.new('libTask', :ios, '6.0') ]

targets.each do |t|
  target t.target.to_sym, exclusive: true do
    platform t.platform, t.platform_version

    # Pods for the framework/library targets
  end

  target "#{t.target}Tests".to_sym, exclusive: true do
    platform t.platform, t.platform_version

    # Pods for the test targets
    pod 'URLMock/TestHelpers', '~> 1.2.3' 
  end
end
