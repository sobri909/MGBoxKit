Pod::Spec.new do |s|
  s.name              = "MGBoxKit"
  s.version           = "8.1.0"
  s.summary           = "Simple, quick iOS tables, grids, and more"
  s.homepage          = "https://github.com/sobri909/MGBoxKit"
  s.license           = { :type => "BSD", :file => "LICENSE" }
  s.author            = { "Matt Greenfield" => "matt@bigpaua.com" }
  s.source            = { :git => "https://github.com/sobri909/MGBoxKit.git", :tag => "8.1.0" }
  s.ios.deployment_target = '9.0'
  s.source_files      = 'MGBoxKit/**/*.{h,m}'
  s.frameworks        = 'QuartzCore', 'UIKit'
  s.requires_arc      = true
  s.dependency        "MGEvents"
  s.dependency        "MGMushParser"
end
