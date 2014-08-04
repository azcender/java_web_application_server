# Class: java_web_application_server
#
# This class installs a java web application onto a tomcat instance
#
# Parameters:
#   (string) application
#              - The application this instance should host
#   (hash)   available_applications
#              - The applications available to host
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
#   (hash)   tomcat_libraries
#               - A hash of libraries that should be added to the tomcat instance
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
  $tomcat_libraries       = '',
  $application            = '',
  $available_applications = '',
  $http_port              = '8080',
  $ajp_port               = '8009',
  $server_port            = '8005',
  $ensure                 = present,
  $instance_basedir       = '/srv/tomcat',
  $application_root       = '') {

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

  # Build a server.xml with resource context
#  ::concat {'/tmp/x_server.xml':
#    mode  => '0644',
#    owner => vagrant,
#    group => vagrant,
#  }
#
#  ::concat::fragment {'server.xml_header':
#    target  => '/tmp/x_server.xml',
#    content => template('java_web_application_server/server_header.xml.erb'),
#    order   => 01,
#  }
#
#  ::concat::fragment {'server.xml_resources':
#    target  => '/tmp/x_server.xml',
#    content => template('java_web_application_server/server_context.xml.erb'),
#    order   => 90,
#  }
#
#  ::concat::fragment {'server.xml_footer':
#    target  => '/tmp/x_server.xml',
#    content => template('java_web_application_server/server_footer.xml.erb'),
#    order   => 99,
#  }

  ::tomcat::instance { $application_root:
    ensure           => $ensure,
    http_port        => $http_port,
    ajp_port         => $ajp_port,
    server_port      => $server_port,
    instance_basedir => $instance_basedir,
  }

  # Since the tomcat_libraries use Maven coordinates we need enhance the
  # facade with default values
  $tomcat_libraries_default = {
    instance_basedir => $instance_basedir,
    application_root => $application_root,
    ensure           => $ensure,
  }

  # The keys for the Tomcat libraries
  $tomcat_libraries_keys = keys($tomcat_libraries)

  # Iterate the tomcat libraries and install in the Tomcat instance
  ::java_web_application_server::maven { "$application_root-$tomcat_libraries_keys":
    tomcat_libraries => $tomcat_libraries,
    instance_basedir => $instance_basedir,
    application_root => $application_root,
    ensure           => $ensure,
  }

  # Add the tomcat libraries
#  create_resources(
#    '::java_web_application_server::maven',
#    $tomcat_libraries,
#    $tomcat_libraries_default)

  # The application install directory is based off of the Tomcat instance
  # base directory
  $maven_application_directory  =
    "${instance_basedir}/${application_root}/webapps/${application_root}.war"

  # Currently using an if statement since maven does not have an ensure
  # property. Need to address
  if $ensure != 'absent' {
    maven { $maven_application_directory:
      groupid    => "$available_applications[$application]['group_id']",
      artifactid => "$available_applications[$application]['artifact_id']",
      version    => "$available_applications[$application]['version']",
      repos      => "$available_applications[$application]['repository']",
      packaging  => 'war',
    }
  }
}