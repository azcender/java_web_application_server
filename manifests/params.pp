# Class: java_web_application_server
#
# This class installs a java web application onto a tomcat instance
#
# Parameters:
#   application_name   - Name of the application
#   group_id           - Maven group ID coordinate
#   artifact_id        - Maven artifact ID coordinate
#   repository         - Maven repository where this application is kept
#   version            - Version of the application retrieved from Maven repo
#   tomcat_http_port   - HTTP port this application can be found on
#   tomcat_ajp_port    - If AJP is used the web front end can integrate here
#   tomcat_server_port - The server control port for Tomcat
#   httpd_http_port    - Port that httpd listens on
#   httpd_vhost_header - Virtual host header for balancer
#   httpd_docroot      - Path to virtual host's docroot
#   ensure             - present, running, installed, stopped or absent
#   instance_basedir   - The directory the tomcat instance will be installed in
#   application_root   - URI the application will be under: 'http://../myapp'
#
# Actions:
#   Install tomcat instance
#   Install application
#   Restart tomcat service
#
# Requires:
#   camptocamp/tomcat
#   maestrodev/maven
#
class java_web_application_server::params {
}