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
#   puppetlabs/tomcat
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
  $application_root       = '') {

  # This currently requires tomcat and maven classes
  require ::tomcat

  include ::java_web_application_server::params

  # Create the instance directory based of application name
  $instance_dir = "/srv/tomcat/${application}"

  # Validate application list is a hash
  validate_hash($available_applications)
  validate_hash($available_resources)

  # Check hash values
  validate_string("${available_applications[$application][group_id]}")
  validate_string("${available_applications[$application][artifact_id]}")
  validate_string("${available_applications[$application][version]}")

  # The following line doesn't work properly. Sees an array of size one as a
  # string
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

#  ::tomcat::instance { $application_root:
#    ensure              => $ensure,
#    http_port           => $http_port,
#    ajp_port            => $ajp_port,
#    server_port         => $server_port,
#    instance_basedir    => $instance_basedir,
#    available_resources => $available_resources,
#    resources           => $resources,
#  }

  ::tomcat::instance { $application:
    catalina_base => $instance_dir,
    source_url    => 'http://mirror.cogentco.com/pub/apache/tomcat/tomcat-7/v7.0.55/bin/apache-tomcat-7.0.55.tar.gz'
  }->
  tomcat::config::server { $application:
    catalina_base => $instance_dir,
    port          => $server_port,
  }->
  tomcat::config::server::connector { "${application}-http":
    catalina_base         => $instance_dir,
    port                  => $http_port,
    protocol              => 'HTTP/1.1',
  }->
  tomcat::config::server::connector { "${application}-ajp":
    catalina_base         => $instance_dir,
    port                  => $ajp_port,
    protocol              => 'AJP/1.3',
  }->
  tomat::config::context { $application:
    catalina_base => $instance_dir,
  }->
  tomcat::service { $application:
    catalina_base => $instance_dir,
  }

  create_resources('tomcat::config::context::resource', $resources)
}
