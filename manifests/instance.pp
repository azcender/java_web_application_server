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
#   (int)    tomcat_http_port
#              - HTTP port this application can be found on
#   (int)    tomcat_ajp_port
#               - If AJP is used the web front end can integrate here
#   (int)    tomcat_server_port
#               - The server control port for Tomcat
#   (string) balancer
#               - Name of the balancer tomcat instance is assigned to
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
  $instance_basedir,
  $source_url,
  $applications          = {},
  $tomcat_http_port      = '8080',
  $tomcat_ajp_port       = '8009',
  $tomcat_server_port    = '8005',
  $balancer              = '',
  $ensure                = present,
  $remove_examples       = true,
  $resource_links        = {},
  $globalnamingresources = {},
  $resources             = {}) {

  include ::java_web_application_server::params

  # Validate application list and resource list are arryas
  validate_hash($applications)
  validate_hash($resources)

  # Do validation of tomcat ports
  validate_re($tomcat_server_port, '^[0-9]+$')
  validate_re($tomcat_http_port, '^[0-9]+$')
  validate_re($tomcat_ajp_port, '^[0-9]+$')

  # Validate Maven coordinates and other strings
  validate_string($name)
  validate_string($instance_basedir)
  validate_string($httpd_vhost_header)
  validate_string($httpd_docroot)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'absent'
    ])

  # if the balancer is empty, or false skip. Else export balancer member.
  if ! empty($balancer) {
    @@::apache::balancermember { "${name}-${fqdn}":
      balancer_cluster => $balancer,
      url              => "ajp://${::fqdn}:$tomcat_ajp_port",
      options          => ['ping=5', 'retry=5', 'ttl=120', "route=${name}"],
    }
  }

  # Create the instance directory based of application name
  $instance_dir = "${instance_basedir}/${name}"

  ::tomcat::instance { $name:
    catalina_base => $instance_dir,
    source_url    => $source_url,
  }

 ::tomcat::config::server { $name:
    catalina_base => $instance_dir,
    port          => $tomcat_server_port,
    require       => ::Tomcat::Instance[$name],
  }

  ::tomcat::config::server::connector { "${name}-http":
    catalina_base         => $instance_dir,
    port                  => $tomcat_http_port,
    protocol              => 'HTTP/1.1',
    additional_attributes => {
      'connectionTimeout' => '10000'
    },
    require               => ::Tomcat::Config::Server[$name],
  }

  ::tomcat::config::server::connector { "${name}-ajp":
    catalina_base         => $instance_dir,
    port                  => $tomcat_ajp_port,
    protocol              => 'AJP/1.3',
    additional_attributes => {
      'connectionTimeout' => '10000'
    },
    require               => ::Tomcat::Config::Server[$name],
  }

  ::tomcat::config::server::engine { "${name}-engine":
    catalina_base => $instance_dir,
    default_host  => 'localhost',
    jvm_route     => $name,
    engine_name   => 'Catalina',
    require       => ::Tomcat::Config::Server[$name],
  }

  ::tomcat::config::context { $name:
    catalina_base => $instance_dir,
    require       => ::Tomcat::Instance[$name],
  }

  ::tomcat::service { "${name}":
    service_name  => "${name}",
    catalina_home => $instance_dir,
    catalina_base => $instance_dir,
    require       => [::Tomcat::Config::Server[$name]],
  }

  # Setup server globalnamingresources
  $globalnamingresources_defaults = {
    catalina_base => $instance_dir,
    require       => ::Tomcat::Config::Server[$name],
  }

  create_resources('::tomcat::config::server::globalnamingresources',
                   $globalnamingresources, $globalnamingresources_defaults)

  # Setup context resources
  $resource_defaults = {
    catalina_base => $instance_dir,
    require       => ::Tomcat::Config::Context[$name],
  }

  create_resources('::tomcat::config::context::resource', $resources,
                   $resource_defaults)

  # Setup context resources
  $resource_link_defaults = {
    catalina_base => $instance_dir,
    require       => ::Tomcat::Config::Context[$name],
  }

  create_resources('::tomcat::config::context::resourcelink', $resource_links,
                   $resource_link_defaults)


  # Install apps
  $application_defaults = {
    catalina_base => $instance_dir,
    require       => ::Tomcat::Instance[$name],
  }

  create_resources('::java_web_application_server::maven', $applications, $application_defaults)
}
