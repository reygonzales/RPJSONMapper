Pod::Spec.new do |s|
  s.name         = "RPJSONMapper"
  s.version      = "1.0.0"
  s.summary      = "JSON to object property mapper"
  s.homepage     = "https://github.com/reygonzales/RPJSONMapper"
  s.license      = 'MIT'
  s.author       = { "Rey Gonzales" => "reynaldo@mail.sfsu.edu" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/reygonzales/RPJSONMapper.git", :tag => s.version.to_s }
  s.source_files = 'RPJSONMapper/*.{h,m}'
  s.framework 	 = 'Foundation'
  s.requires_arc = true
end
