# Class: java_web_application_server::maven
#
# This class normalizes a maven hash so that it installs in the proper location
# for a tomcat instance
#
# Parameters:
#   name             (String)
#     - The application root concat with the tomcat library key
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

  # Get the hash key
  $key = split($name, '_')

  # tomcat_libraries must be a hash
  validate_hash($tomcat_libraries)

  # Application root cannot have apaces
  validate_re($application_root, '^[\S]+$')

  # Validate Maven coordinates and other strings
  validate_string($tomcat_libraries[$key[1]]['groupid'])

  validate_string($tomcat_libraries[$key[1]]['artifactid'])
  validate_string($tomcat_libraries[$key[1]]['version'])
  validate_string($tomcat_libraries[$key[1]]['packaging'])

  # Validate repos are an array
  validate_array($tomcat_libraries[$key[1]]['repos'])

  # Create local vars from hash
  $groupid    = $tomcat_libraries[$key[1]]['groupid']
  $artifactid = $tomcat_libraries[$key[1]]['artifactid']
  $version    = $tomcat_libraries[$key[1]]['version']
  $packaging  = $tomcat_libraries[$key[1]]['packaging']
  $repos      = $tomcat_libraries[$key[1]]['repos']

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