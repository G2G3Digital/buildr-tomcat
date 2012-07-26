buildr-tomcat
=============

buildr-tomcat provides a plugin for Buildr that allows you to run a war-packaged project in an embedded Tomcat.
It is largely based on the Jetty pplugin, but is somewhat simplified.

Example:

	define "my-webapp" do
		compile.with # some dependencies here
		package(:war)

		task('tomcat') do |task|
			Buildr::Tomcat::explode(self)
			Buildr::Tomcat.new("crsc", "http://localhost:8084/my-webapp", "my-webapp/target/my-webapp-#{VERSION_NUMBER}").run

			trap 'SIGINT' do
				puts "Stopping Tomcat"
				tomcat.stop
			end
			Thread.stop
		end
	end

