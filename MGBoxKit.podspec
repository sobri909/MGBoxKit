Pod::Spec.new do |s|
  s.name              = "MGBoxKit"
  s.version           = "6.0.0"
  s.summary           = "Simple, quick iOS tables, grids, and more"
  s.homepage          = "https://github.com/sobri909/MGBoxKit"
  s.license           = { :type => "BSD", :file => "LICENSE" }  
  s.author            = { "Matt Greenfield" => "matt@bigpaua.com" }
  s.source            = { :git => "https://github.com/sobri909/MGBoxKit.git", :tag => "6.0.0" }
  s.platform          = :ios, '6.0'
  s.source_files      = 'MGBoxKit/**/*.{h,m}'
  s.framework         = 'QuartzCore', 'CoreText'
  s.requires_arc      = true
  s.dependency        "MGEvents"
end
