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
  $applications        = [],
  $tomcat_http_port    = '8080',
  $tomcat_ajp_port     = '8009',
  $tomcat_server_port  = '8005',
  $httpd_http_port,
  $httpd_vhost_header,
  $httpd_docroot,
  $ensure              = present,
  $remove_examples     = true,
  $instance_basedir,
  $source_url,
  $resources           = []) {

  # This currently requires tomcat and maven classes
  require ::tomcat

  include ::java_web_application_server::params

  # Validate application list and resource list are arryas
  validate_hash($applications)
  validate_hash($resources)

  # Do validation of ports
  validate_re($tomcat_server_port, '^[0-9]+$')
  validate_re($tomcat_http_port, '^[0-9]+$')
  validate_re($tomcat_ajp_port, '^[0-9]+$')
  validate_re($httpd_http_port, '^[0-9]+$')

  # Validate Maven coordinates and other strings
  validate_string($name)
  validate_string($instance_basedir)
  validate_string($application)
  validate_string($httpd_vhost_header)
  validate_string($httpd_docroot)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'absent'
    ])

  # Apache submodules required for proxy
  apache::mod { 'proxy_ajp': }
  apache::mod { 'proxy_balancer': }
  apache::mod { 'proxy_html': }
  apache::mod { 'proxy_http': }

  # Add the Apache balancer front end
  ::apache::balancer { $name:
    collect_exported  => false,
  }

  ::apache::balancermember { $name:
    balancer_cluster => $name,
    url              => "ajp://${::fqdn}:$tomcat_ajp_port",
    options          => ['ping=5', 'disablereuse=on', 'retry=5', 'ttl=120'],
  }

  $proxy_pass = [
    { 'path' => '/',  'url' => "balancer://${name}/" },
    { 'path' => '/*', 'url' => "balancer://${name}/" }
  ]

  apache::vhost { "vhost-${name}":
    servername   => $httpd_vhost_header,
    port         => $httpd_http_port,
    docroot      => $httpd_docroot,
    proxy_pass   => $proxy_pass,
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
    require               => ::Tomcat::Config::Server[$name]
  }

  ::tomcat::config::context { $name:
    catalina_base => $instance_dir,
    require       => ::Tomcat::Instance[$name],
  }

  ::tomcat::service { "${name}":
    #use_init      => true,
    service_name  => "${name}",
    catalina_home => $instance_dir,
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
