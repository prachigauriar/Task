source 'https://github.com/CocoaPods/Specs.git'

Target = Struct.new(:target, :platform, :platform_version)

[ Target.new('Task', :osx, '10.8'), Target.new('Task (iOS)', :ios, '6.1'), Target.new('libTask', :ios, '6.1') ].each do |t|
  target t.target.to_sym, exclusive: true do
    platform t.platform, t.platform_version

    # Pods for the framework/library targets
  end

  target "#{t.target} Tests".to_sym, exclusive: true do
    platform t.platform, t.platform_version

    # Pods for the test targets
    pod 'URLMock/TestHelpers', '~> 1.2.1' 
  end
end
