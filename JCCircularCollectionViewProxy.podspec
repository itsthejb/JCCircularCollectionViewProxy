Pod::Spec.new do |s|
  s.name          = "JCCircularCollectionViewProxy"
  s.version       = "1.0.0"
  s.summary       = "Quasi-infinite scrolling circular UICollectionView."
  s.description   = "Create a padded, infinite scrolling UICollectionViewFlowLayout with very little code."
  s.homepage      = "<#repository homepage#>"
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.author        = { "Jonathan Crooke" => "jon.crooke@gmail.com" }
  s.source        = { :git => "<#repository#>", :tag => "v" + s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.source_files  = s.name + '/*.{h,m}'
  s.frameworks    = 'UIKit'
  s.requires_arc  = true
end
