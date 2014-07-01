# Class: java_web_application_server
#
# This class installs a java web application onto a tomcat instance
#
# Parameters:
#   application_name - Name of the application
#   group_id         - Maven group ID coordinate
#   artifact_id      - Maven artifact ID coordinate
#   repository       - Maven repository where this application is kept
#   version          - Version of the application retrieved from Maven repo
#   http_port        - HTTP port this application can be found on
#   ajp_port         - If AJP is used the web front end can integrate here
#   server_port      - The server control port for Tomcat
#   ensure           - present, running, installed, stopped or absent
#   instance_basedir - The directory the tomcat instance will be installed in
#   application_root - URI the application will be under: 'http://../myapp'
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
define java_web_application_server::instance (
  $application_name = '',
  $group_id         = '',
  $artifact_id      = '',
  $repository       = '',
  $version          = '',
  $http_port        = '8080',
  $ajp_port         = '8009',
  $server_port      = '8005',
  $ensure           = present,
  $instance_basedir = '/srv/tomcat',
  $application_root = '') {

  include ::java_web_application_server::params

  # Do validation of ports
  validate_re($server_port, '^[0-9]+$')
  validate_re($http_port, '^[0-9]+$')
  validate_re($ajp_port, '^[0-9]+$')

  # Validate Maven coordinates and other strings
  validate_string($application_name)
  validate_string($group_id)
  validate_string($artifact_id)
  validate_string($repository)
  validate_string($version)
  validate_string($instance_basedir)
  validate_string($application_root)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'running',
    'stopped',
    'installed',
    'absent'
    ])

  ::tomcat::instance { $application_name:
    ensure           => $ensure,
    http_port        => $http_port,
    ajp_port         => $ajp_port,
    server_port      => $server_port,
    instance_basedir => $instance_basedir,
  }

  # The application install directory is based off of the Tomcat instance
  # base directory
  $maven_application_directory  =
    "${instance_basedir}/${application_name}/webapps/${application_root}.jar"

  ::maven { $maven_application_directory:
    groupid     => $group_id,
    artifact_id => $artifact_id,
    version     => $version,
    repository  => $repository,
  }
}