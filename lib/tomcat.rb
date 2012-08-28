require 'thread'

module Buildr
  
class Tomcat

    # Which version of Tomcat we're using by default (change with options.tomcat.version).
    VERSION = "6.1.3"
    SLF4J_VERSION = "1.4.3"

    TOMCAT_VERSION = '7.0.21'
    TOMCAT = [ "org.apache.tomcat.embed:tomcat-embed-jasper:jar:#{TOMCAT_VERSION}", "org.apache.tomcat:tomcat-catalina:jar:#{TOMCAT_VERSION}", "org.apache.tomcat:tomcat-jasper:jar:#{TOMCAT_VERSION}", "org.apache.tomcat:tomcat-servlet-api:jar:#{TOMCAT_VERSION}", "org.apache.tomcat.embed:tomcat-embed-core:jar:#{TOMCAT_VERSION}", "org.apache.tomcat.embed:tomcat-embed-logging-log4j:jar:#{TOMCAT_VERSION}" ]

    Java.classpath << File.dirname(__FILE__)
    Java.classpath << TOMCAT



    # Default URL fort  (change with options.tomcat.url).
    URL = "http://localhost:8080"

    class << self

      # :call-seq:
      #   instance() => Tomcat
      #
      # Returns an instance of Tomcat.
      def instance()
        @instance ||= Tomcat.new("", URL)
      end

      #
      # Explode a war-file into the target directory.
      #
      #
      def explode(project)
        name = project.name.split(':').last
        dirname = "#{name}/target/#{name}-#{VERSION_NUMBER}"

        if !File.exists? dirname
          system("unzip -q #{name}/target/#{name}-#{VERSION_NUMBER}.war -d #{dirname}")
        end
      end
    end

    def initialize(name, url, webAppLocation) #:nodoc:
      @webAppLocation = webAppLocation
      @url = url
      namespace name do
        @setup = task("setup")
        @teardown = task("teardown")
        @use = task("use") { fire }
      end
    end

    # The URL for the Tomcat server. Leave as is if you want to use the default server
    # (http://localhost:8080).
    attr_accessor :url

    # :call-seq:
    #    start(pipe?)
    #
    # Starts Tomcat. This method does not return, it keeps the thread running until
    # Tomcat is stopped. If you want to run Tomcat parallel with other tasks in the build,
    # invoke the #use task instead.
    def start(sync = nil)
      begin
        puts "classpath #{Java.classpath.inspect}"
        port = URI.parse(url).port
        puts "***** Starting Tomcat at http://localhost:#{port}"
        Java.load
	tomcat = Java.com.technophobia.buildr.tomcat.TomcatWrapper.new(port, URI.parse(url).path, @webAppLocation)
	
	puts "***** Tomcat has started up *****"
        sync << "Started" if sync
        sleep # Forever
      rescue Interrupt # Stopped from console
	puts "Interrupted"
      rescue Exception=>error
        puts "#{error.class}: #{error.message}"
      end
      exit! # No at_exit
    end

    def run() 
        puts "***** RUNNING IN THE BACKGROUND *****"
	use.invoke
    end

    # :call-seq:
    #    stop()
    #
    # Stops Tomcat. Stops a server running in a separate process.
    def stop()
      puts "***** STOPPING TOMCAT *****"
      uri = URI.parse(url)
      begin
        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request_post "/buildr/stop", ""
        end
      rescue Errno::ECONNREFUSED
        # Expected if Tomcat server not running.
      rescue EOFError
        # We get EOFError because Tomcat is brutally killed.
      end
      puts "***** Told tomcat server to stop"
    end


    # :call-seq:
    #   running?() => boolean
    #
    # Returns true if it finds a running Tomcat server that supports the Buildr
    # requests for deploying, stopping, etc.
    def running?()
      puts "Checking if already running..."
      uri = URI.parse(url)
      begin
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.request_get("/buildr/")
          response.is_a?(Net::HTTPSuccess) && response.body =~ /Alive/
        end
      rescue Errno::ECONNREFUSED, Errno::EBADF
        false
      end
    end


    # :call-seq:
    #   setup(*prereqs) => task
    #   setup(*prereqs) { |task| .. } => task
    #
    # This task executes when Tomcat is first used in the build. You can use it to
    # deploy artifacts into Tomcat.
    def setup(*prereqs, &block)
      @setup.enhance prereqs, &block
    end

    # :call-seq:
    #   teardown(*prereqs) => task
    #   teardown(*prereqs) { |task| .. } => task
    #
    # This task executes when the build is done. You can use it to undeploy artifacts
    # previously deployed into Tomcat.
    def teardown(*prereqs, &block)
      @teardown.enhance prereqs, &block
    end

    # :call-seq:
    #   use(*prereqs) => task
    #   use(*prereqs) { |task| .. } => task
    #
    # If you intend to use Tomcat, invoke this task. It will start a new instance of
    # Tomcat and close it when the build is done. However, if you already have a server
    # running in the background (e.g. tomcat:start), it will use that server and will
    # not close it down.
    def use(*prereqs, &block)
      @use.enhance prereqs, &block
    end



  protected

    # If you want to start Tomcat inside the build, call this method instead of #start.
    # It will spawn a separate process that will run Tomcat, and will stop Tomcat when
    # the build ends. However, if you already started Tomcat from the console (with
    # take tomcat:start), it will use the existing instance without shutting it down.
    def fire()
      puts "***** Firing up Tomcat *****"
      unless running?
        sync = Queue.new
        Thread.new { start sync }
        # Wait for Tomcat to Fire up before doing anything else.
        sync.pop == "Started" or fail "Tomcat not started"
        puts "***** Tomcat fired up *****"
        at_exit { stop }
      end
      @setup.invoke
      at_exit { @teardown.invoke }
    end
  end


  namespace "tomcat" do
    desc "Start an instance of Tomcat running in the background"
    task("start") { Tomcat.instance.start }
    desc "Stop an instance of Tomcat running in the background"
    task("stop") { Tomcat.instance.stop }
  end

  # :call-seq:
  #   tomcat() => Tomcat
  #
  # Returns a Tomcat object. You can use this to discover the Tomcat#use task,
  # configure the Tomcat#setup and Tomcat#teardown tasks, deploy and undeploy to Tomcat.
  def tomcat()
    @tomcat ||= Tomcat.instance
  end

end
