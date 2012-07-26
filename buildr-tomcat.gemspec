$LOAD_PATH.unshift 'lib'

Gem::Specification.new do |s|
  s.name              = "buildr-tomcat"
  s.version           = "0.0.1"
  s.date              = '2012-07-26'
  s.summary           = "Tomcat plugin for Buildr"
  s.homepage          = "http://github.com/technophobia/buildr-tomcat"
  s.email             = "rgibson@technophobia.com"
  s.authors           = [ "Rory Gibson" ]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile COPYING.LESSER )
  s.files            += Dir.glob("lib/**/*")

s.description       = <<desc
  Provides the ability to run a war-packaged artifact using an embedded Tomcat. 
desc
end
