# Class: java_web_application_server::maven
#
# This class normalizes a maven hash so that it installs in the proper location
# for a tomcat instance
#
# Parameters:
#   name             (String)
#     - THe tomcat library key
#
#   tomcat_libraries (hash)
#     - The libraries that should be installed on the Tomcat tomcat instance
#
#     groupid    - Maven group id coordinate
#     artifactid - Maven artifact id coordinate
#     version    - Maven version coordinate
#     repos      - Arrar of Maven repositories to search
#     packaging  - jar, war, ear
#
#   ensure           (enum)
#     - present, running, installed, stopped or absent
#
#   instance_basedir (String)
#     - The directory the tomcat instance will be installed in
#
#   application_root (String)
#     - URI the application will be under: 'http://../myapp'
#
# Actions:
#   Install java library in tomcat instance
#
# Requires:
#   maestrodev/maven
#
define java_web_application_server::maven (
  $name,
  $tomcat_libraries,
  $application_root,
  $instance_basedir = '/srv/tomcat',
  $ensure           = 'present') {

  # tomcat_libraries must be a hash
  validate_hash($tomcat_libraries)

  # Application root cannot have apaces
  validate_re($application_root, '^[\S]+$')

  # Validate Maven coordinates and other strings
  validate_string($tomcat_libraries[$name]['groupid'])
  validate_string($tomcat_libraries[$name]['artifactid'])
  validate_string($tomcat_libraries[$name]['version'])
  validate_string($tomcat_libraries[$name]['packaging'])

  # Validate repos are an array
  validate_array($tomcat_libraries[$name]['repos'])

  # Create local vars from hash
  $groupid    = $tomcat_libraries[$name]['groupid']
  $artifactid = $tomcat_libraries[$name]['artifactid']
  $version    = $tomcat_libraries[$name]['version']
  $packaging  = $tomcat_libraries[$name]['packaging']
  $repos      = $tomcat_libraries[$name]['repos']

  validate_string($instance_basedir)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'installed',
    'absent'
    ])

  # Normalize the Maven directory
  $maven_location =
    "${instance_basedir}/${application_root}/lib/${artifactid}-${version}.${packaging}"

  maven {$maven_location:
    groupid    => $groupid,
    artifactid => $artifactid,
    version    => $version,
    repos      => $repos,
  }
}