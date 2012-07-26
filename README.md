buildr-tomcat
=============

buildr-tomcat provides a plugin for Buildr that allows you to run a war-packaged project in an embedded Tomcat.

It is largely based on the Jetty plugin, but is somewhat simplified.

Example:

	define "my-webapp" do
		compile.with # some dependencies here
		package(:war)

		task('tomcat') do |task|
			name = 'my-webapp'
			Buildr::Tomcat::explode(self)
			Buildr::Tomcat.new(name, "http://localhost:8084/#{name}", "#{name}/target/#{name}-#{VERSION_NUMBER}").run

			trap 'SIGINT' do
				puts "Stopping Tomcat"
				tomcat.stop
			end
			Thread.stop
		end
	end

