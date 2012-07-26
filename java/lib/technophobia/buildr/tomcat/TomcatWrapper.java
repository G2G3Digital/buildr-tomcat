package com.technophobia.buildr.tomcat;

import java.io.File;
import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.catalina.Context;
import org.apache.catalina.LifecycleException;
import org.apache.catalina.startup.Tomcat;

public class TomcatWrapper {

	public TomcatWrapper(int port, String contextRoot, String path)
			throws ServletException, LifecycleException {
		this(port, contextRoot, path, false);
	}

	public TomcatWrapper(int port, String contextRoot, String path,
			boolean standalone) throws ServletException, LifecycleException {
		
		Runtime.getRuntime().addShutdownHook(new Thread() {
			@Override
			public void run() {			
				super.run();
				System.out.println("Shutdown hook");
			}
		});

		final Tomcat tomcat = new Tomcat();
		tomcat.addWebapp(contextRoot, new File(path).getAbsolutePath());

		tomcat.setPort(port);
		tomcat.enableNaming();

		Context ctx = tomcat.addContext("/", new File(".").getAbsolutePath());

		Tomcat.addServlet(ctx, "stop", new HttpServlet() {
			private static final long serialVersionUID = 8337145729398470928L;

			protected void service(HttpServletRequest req,
					HttpServletResponse resp) throws ServletException,
					IOException {
				try {
					System.out.println("Stopping Tomcat");
					tomcat.stop();
					System.out.println("... stopped");
				} catch (LifecycleException e) {
					System.out.println("Exception while shutting down Tomcat");
					e.printStackTrace();
				}
			}
		});
		
		ctx.addServletMapping("/buildr/stop", "stop");

		try {
			tomcat.start();

			if (standalone) {
				tomcat.getServer().await();
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) throws ServletException,
			LifecycleException {
		new TomcatWrapper(8090, "/manager", "/tmp/manager", true);
	}

}
