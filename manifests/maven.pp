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
  $war_name,
  $groupid,
  $artifactid,
  $version,
  $maven_repo,
  $catalina_base,
  $packaging = 'jar',
  $ensure    = 'present') {

  # Validate Maven coordinates and other strings
  validate_string($groupid)
  validate_string($artifactid)
  validate_string($version)
  validate_string($catalina_base)
  validate_string($maven_repo)

  validate_re($packaging, [
    'war',
    'ear',
    'jar'
    ])

  $_group_id = regsubst($groupid, '\.', '/', 'G')

  $application_url =
    "${maven_repo}/${_group_id}/${artifactid}/${version}/${artifactid}-${version}.${packaging}"

  ::tomcat::war { "${catalina_base}-${name}.war" :
    catalina_base => $catalina_base,
    war_source    => $application_url,
    war_name      => $war_name, 
  }
}