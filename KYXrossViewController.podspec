Pod::Spec.new do |s|
  s.name             = "KYXrossViewController"
  s.version          = "0.4.2"
  s.summary          = "All-directions-enabled UIPageViewController"

  s.homepage         = "https://github.com/ML-Works/frontend"
  s.license          = 'MIT'
  s.author           = { "Anton Bukov" => "k06aaa@gmail.com" }
  s.source           = { :svn => "https://github.com/ML-Works/frontend/tags/KYXrossViewController/#{s.version}/libraries/KYXrossViewController" }
  
  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/**/*'
  
  s.public_header_files = 'Pod/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'JRSwizzle'
  s.dependency 'libextobjc'
  s.dependency 'KVOController'
  s.dependency 'NCController'
end
