# Class: java_web_application_server
#
# This class installs a java web application onto a tomcat instance
#
# Parameters:
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
#   tomcat_libraries - A hash of libraries that should be added to the tomcat
#                      instance
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
  $tomcat_libraries,
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

  notify {$tomcat_libraries: }

  # This currently requires tomcat and maven classes
  require tomcat, maven::maven

  include ::java_web_application_server::params

  # Do validation of ports
  validate_re($server_port, '^[0-9]+$')
  validate_re($http_port, '^[0-9]+$')
  validate_re($ajp_port, '^[0-9]+$')

  # Application root cannot have apaces
  validate_re($application_root, '^[\S]+$')

  # Validate Maven coordinates and other strings
  validate_string($group_id)
  validate_string($artifact_id)
  validate_string($repository)
  validate_string($version)
  validate_string($instance_basedir)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'running',
    'stopped',
    'installed',
    'absent'
    ])

  ::tomcat::instance { $application_root:
    ensure           => $ensure,
    http_port        => $http_port,
    ajp_port         => $ajp_port,
    server_port      => $server_port,
    instance_basedir => $instance_basedir,
  }

  # Create the libraries for the instance
  #  create_resources('maven', $tomcat_libraries)

  # The application install directory is based off of the Tomcat instance
  # base directory
  $maven_application_directory  =
    "${instance_basedir}/${application_root}/webapps/${application_root}.war"

  # Currently using an if statement since maven does not have an ensure
  # property. Need to address
  if $ensure != 'absent' {
    maven { $maven_application_directory:
      groupid    => $group_id,
      artifactid => $artifact_id,
      version    => $version,
      repos      => $repository,
      packaging  => 'war',
    }
  }
}