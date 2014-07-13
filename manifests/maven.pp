# Class: java_web_application_server::maven
#
# This class normalizes a maven hash so that it installs in the proper location
# for a tomcat instance
#
# Parameters:
#   group_id         - Maven group ID coordinate
#   artifact_id      - Maven artifact ID coordinate
#   repos            - Maven repository where this application is kept
#   version          - Version of the application retrieved from Maven repo
#   ensure           - present, running, installed, stopped or absent
#   instance_basedir - The directory the tomcat instance will be installed in
#   application_root - URI the application will be under: 'http://../myapp'
#
# Actions:
#   Install java library in tomcat instance
#
# Requires:
#   maestrodev/maven
#
define java_web_application_server::maven (
  $groupid,
  $artifactid,
  $repos,
  $version,
  $application_root,
  $instance_basedir = '/srv/tomcat',
  $ensure           = 'present') {

  # Application root cannot have apaces
  validate_re($application_root, '^[\S]+$')

  # Validate Maven coordinates and other strings
  validate_string($group_id)
  validate_string($artifact_id)
  validate_string($version)
  validate_string($instance_basedir)

  # Check ensure types
  validate_re($ensure, [
    'present',
    'installed',
    'absent'
    ])

  # Normalize the Maven directory
  $maven_location =
    "${instance_basedir}/${application_root}/lib/${artifact_id}-${version}.jar"

  maven {$maven_location:
    groupid    => $group_id,
    artifactid => $artifact_id,
    version    => $version,
    repos      => $repos,
  }
}