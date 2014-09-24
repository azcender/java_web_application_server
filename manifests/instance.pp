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
  $applications     = [],
  $http_port        = '8080',
  $ajp_port         = '8009',
  $server_port      = '8005',
  $ensure           = present,
  $remove_examples  = true,
  $instance_basedir,
  $source_url,
  $resources        = []) {

  # This currently requires tomcat and maven classes
  require ::tomcat

  include ::java_web_application_server::params

  # Validate application list and resource list are arryas
  validate_hash($applications)
  validate_hash($resources)

  # Do validation of ports and application
  validate_re($server_port, '^[0-9]+$')
  validate_re($http_port, '^[0-9]+$')
  validate_re($ajp_port, '^[0-9]+$')

  # Validate Maven coordinates and other strings
  validate_string($name)
  validate_string($instance_basedir)
  validate_string($application)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'absent'
    ])

  # Create the instance directory based of application name
  $instance_dir = "${instance_basedir}/${name}"

  ::tomcat::instance { $name:
    catalina_base => $instance_dir,
    source_url    => $source_url,
  }

 ::tomcat::config::server { $name:
    catalina_base => $instance_dir,
    port          => $server_port,
    require       => ::Tomcat::Instance[$name],
  }

  ::tomcat::config::server::connector { "${name}-http":
    catalina_base         => $instance_dir,
    port                  => $http_port,
    protocol              => 'HTTP/1.1',
    additional_attributes => {
      'connectionTimeout' => '10000'
    },
    require               => ::Tomcat::Config::Server[$name],
  }

  ::tomcat::config::server::connector { "${name}-ajp":
    catalina_base         => $instance_dir,
    port                  => $ajp_port,
    protocol              => 'AJP/1.3',
    require               => ::Tomcat::Config::Server[$name]
  }

  ::tomcat::config::context { $name:
    catalina_base => $instance_dir,
    require       => ::Tomcat::Instance[$name],
  }

  ::tomcat::service { $name:
    use_init      => true,
    service_name  => 'tomcat-${name}',
    catalina_base => $instance_dir,
    require       => [::Tomcat::Config::Server[$name]],
  }

  # Remove example apps
  # if $remove_examples {
      file { "${instance_dir}/webapps/examples":
        ensure => absent,
      }
  # }

  # Setup context resources
  $resource_defaults = {
    catalina_base => $instance_dir,
    require       => ::Tomcat::Config::Context[$name],
  }

  create_resources('::tomcat::config::context::resource', $resources, $resource_defaults)

  # Install apps
  $application_defaults = {
    catalina_base => $instance_dir,
  }

  create_resources('::java_web_application_server::maven', $applications, $application_defaults)
}
