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
  $application_root       = '') {

  # This currently requires tomcat and maven classes
  require tomcat, maven::maven

  include ::java_web_application_server::params

  notify {"$available_resources)": }

  # Validate application list is a hash
  validate_hash($available_applications)
  validate_hash($available_resources)

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

  # Install the ADF libraries. This method is clunky and should probably be
  # done through Hiera. Unfortunantly Puppet does not provide any elgant
  # iterative solutions for production use. For the moment these libraries
  # are hard coded.

  maven { "${instance_basedir}/${application_root}/lib/xdb.jar":
      groupid    => 'com.oracle.external',
      artifactid => 'xdb',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/oc4j-ws-support-impl.jar":
      groupid    => 'com.oracle.webservices.fmw',
      artifactid => 'oc4j-ws-support-impl',
      version    => '1.0.0-SNAPSHOT',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/classloader.jar":
      groupid    => 'com.oracle',
      artifactid => 'classloader',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/http_client.jar":
      groupid    => 'com.oracle',
      artifactid => 'http_client',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/logging-utils.jar":
      groupid    => 'com.oracle',
      artifactid => 'logging-utils',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/web-common.jar":
      groupid    => 'com.oracle',
      artifactid => 'web-common',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/web-common-schemas.jar":
      groupid    => 'com.oracle',
      artifactid => 'web-common-schemas',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/bcel.jar":
      groupid    => 'org.apache',
      artifactid => 'bcel',
      version    => '5.1',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/beanutils.jar":
      groupid    => 'org.apache.commons',
      artifactid => 'beanutils',
      version    => '1.8.3',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/logging.jar":
      groupid    => 'org.apache.commons',
      artifactid => 'logging',
      version    => '1.1.1',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adf-controller-security.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adf-controller-security',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adf-share-security.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adf-share-security',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adf-share-support.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adf-share-support',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adflogginghandler.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adflogginghandler',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adfsharembean.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adfsharembean',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/commons-el.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'commons-el',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/jsp-el-api.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'jsp-el-api',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/oracle-el.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'oracle-el',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adf-share-base.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adf-share-base',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/adf-share-ca.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'adf-share-ca',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/share.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'share',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/dms.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'dms',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/javamodel-rt.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'javamodel-rt',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/javatools-nodeps.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'javatools-nodeps',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/oicons.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'oicons',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/resourcebundle.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'resourcebundle',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/ojdbc6dms.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'ojdbc6dms',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/jrf-api.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'jrf-api',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/globaltldcache.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'globaltldcache',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/mdsrt.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'mdsrt',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/orai18n-mapping.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'orai18n-mapping',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/ojdl.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'ojdl',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/ojdl2.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'ojdl2',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/xmlparserv2_sans_jaxp_services.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'xmlparserv2_sans_jaxp_services',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
  }

  maven { "${instance_basedir}/${application_root}/lib/xmlef.jar":
      groupid    => 'com.oracle.adf',
      artifactid => 'xmlef',
      version    => '12.1.2-0-0',
      repos      => ['http://artifactory.azcender.com/artifactory/oracle-libs-release'],
      packaging  => 'jar',
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
      repos      => "${available_applications[$application][repos]}",
      packaging  => 'war',
    }
  }
}