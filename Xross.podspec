Pod::Spec.new do |s|
  s.name             = "Xross"
  s.version          = "0.7.0"
  s.summary          = "All-directions-enabled UIPageViewController"

  s.homepage         = "https://github.com/ML-Works/Xross"
  s.license          = 'MIT'
  s.author           = { "Anton Bukov" => "k06a@mlworks.com" }
  s.source           = { :git => "https://github.com/ML-Works/Xross.git", :tag => "#{s.version}" }
  
  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/**/*'
  
  s.public_header_files = 'Pod/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'JRSwizzle'
  s.dependency 'libextobjc'
  s.dependency 'KVOController'
  s.dependency 'NCController'
  s.dependency 'UAObfuscatedString'
end
