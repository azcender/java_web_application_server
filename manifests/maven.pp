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
  $groupid,
  $artifactid,
  $version,
  $repos,
  $packaging,
  $library_directory = '/usr/share/tomcat6/lib',
  $ensure            = 'present') {

  # Ensure maven is here
  require ::maven::maven

  # Validate Maven coordinates and other strings
  validate_string($groupid)
  validate_string($artifactid)
  validate_string($version)
  validate_string($library_directory)

  validate_re($packaging, [
    'war',
    'ear',
    'jar'
    ])

  # Repo array is requied and an array
  validate_array($repos)

  $maven_location =
    "${library_directory}/${artifactid}-${version}.${packaging}"

  maven {$maven_location:
    groupid    => $groupid,
    artifactid => $artifactid,
    version    => $version,
    repos      => $repos,
  }
}