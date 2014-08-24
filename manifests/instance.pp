# Class: java_web_application_server
#
# This class installs a java web application onto a tomcat instance
#
# Parameters:
#   (string) application
#              - The application this instance should host
#   (hash)   available_applications
#              - The applications available to host
#   (has)    available_resources
#              - The resources available to the applications
#   (int)    http_port
#              - HTTP port this application can be found on
#   (int)    ajp_port
#               - If AJP is used the web front end can integrate here
#   (int)    server_port
#               - The server control port for Tomcat
#   (enum)   ensure
#               - present, running, installed, stopped or absent
#   (string) instance_basedir
#               - The directory the tomcat instance will be installed
#   (string) application_root
#               - URI the application will be under: 'http://../myapp'
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
  $application            = '',
  $available_applications = '',
  $available_resources    = '',
  $http_port              = '8080',
  $ajp_port               = '8009',
  $server_port            = '8005',
  $ensure                 = present,
  $instance_basedir       = '/srv/tomcat',
  $repos                  = '[]',
  $application_root       = '') {

  # This currently requires tomcat and maven classes
  require tomcat, maven::maven

  include ::java_web_application_server::params

  # Validate application list is a hash
  validate_hash($available_applications)
  validate_hash($available_resources)

  # Validate repos list is an array
  validate_array($repos)

  # Check hash values
  validate_string("${available_applications[$application][group_id]}")
  validate_string("${available_applications[$application][artifact_id]}")
  validate_string("${available_applications[$application][version]}")

  # The following line doesn't work properly. Sees an array of size one as a
  # string
  # validate_array("${available_applications[$application][repos]}")
  # validate_hash("${available_applications[$application][resources]}")

  $resources = $available_applications[$application][resources]

  # Do validation of ports and application
  validate_re($server_port, '^[0-9]+$')
  validate_re($http_port, '^[0-9]+$')
  validate_re($ajp_port, '^[0-9]+$')

  # Application root cannot have apaces
  validate_re($application_root, '^[\S]+$')

  # Validate Maven coordinates and other strings
  validate_string($instance_basedir)
  validate_string($application)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'running',
    'stopped',
    'installed',
    'absent'
    ])

  ::tomcat::instance { $application_root:
    ensure              => $ensure,
    http_port           => $http_port,
    ajp_port            => $ajp_port,
    server_port         => $server_port,
    instance_basedir    => $instance_basedir,
    available_resources => $available_resources,
    resources           => $resources,
  }

  # The application install directory is based off of the Tomcat instance
  # base directory
  $maven_application_directory  =
    "${instance_basedir}/${application_root}/webapps/${application_root}.war"

  # Currently using an if statement since maven does not have an ensure
  # property. Need to address
  if $ensure != 'absent' {
    maven { $maven_application_directory:
      groupid    => "${available_applications[$application][group_id]}",
      artifactid => "${available_applications[$application][artifact_id]}",
      version    => "${available_applications[$application][version]}",
      repos      => $repos,
      packaging  => 'war',
      ensure     => 'latest',
    }
  }
}
