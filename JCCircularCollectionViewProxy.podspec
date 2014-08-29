Pod::Spec.new do |s|
  s.name          = "JCCircularCollectionViewProxy"
  s.version       = "0.0.1"
  s.summary       = "Quasi-infinite scrolling circular UICollectionView."
  s.description   = "Create a padded, infinite scrolling UICollectionViewFlowLayout with very little code."
  s.homepage      = "https://github.com/itsthejb/JCCircularCollectionViewProxy"
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.author        = { "Jonathan Crooke" => "jon.crooke@gmail.com" }
  s.source        = { :git => "git@github.com:itsthejb/JCCircularCollectionViewProxy.git", :tag => "v" + s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.source_files  = s.name + '/*.{h,m}'
  s.frameworks    = 'UIKit'
  s.requires_arc  = true
end
