# == Class: stash
#
# This configures the stash module. See README.md for details
#
class stash::config(
  $version      = $stash::version,
  $user         = $stash::user,
  $group        = $stash::group,
  $proxy        = $stash::proxy,
  $context_path = $stash::context_path,
  $tomcat_port  = $stash::tomcat_port,
  $config_properties = $stash::config_properties,
) {

  # Atlassian changed where files are installed from ver 3.2.0
  # See issue #16 for more detail
  if versioncmp($version, '3.2.0') > 0 {
    $moved = 'shared/'
    file { "${stash::homedir}/${moved}":
      ensure  => 'directory',
      owner   => $user,
      group   => $group,
      require => File[$stash::homedir],
    }
  } else {
    $moved = undef
  }

  File {
    owner => $stash::user,
    group => $stash::group,
  }

  if versioncmp($version, '3.8.0') >= 0 {
    $server_xml = "${stash::homedir}/shared/server.xml"
  } else {
    $server_xml = "${stash::webappdir}/conf/server.xml"
  }

  file { "${stash::webappdir}/bin/setenv.sh":
    content => template('stash/setenv.sh.erb'),
    mode    => '0750',
    require => Class['stash::install'],
    notify  => Class['stash::service'],
  } ->

  file { "${stash::webappdir}/bin/user.sh":
    content => template('stash/user.sh.erb'),
    mode    => '0750',
    require => [
      Class['stash::install'],
      File[$stash::webappdir],
      File[$stash::homedir]
    ],
  }->

  file { $server_xml:
    content => template('stash/server.xml.erb'),
    mode    => '0640',
    require => Class['stash::install'],
    notify  => Class['stash::service'],
  } ->

  ini_setting { 'stash_httpport':
    ensure  => present,
    path    => "${stash::webappdir}/conf/scripts.cfg",
    section => '',
    setting => 'stash_httpport',
    value   => $tomcat_port,
    require => Class['stash::install'],
    before  => Class['stash::service'],
  } ->

  file { "${stash::homedir}/${moved}stash-config.properties":
    content => template('stash/stash-config.properties.erb'),
    mode    => '0640',
    require => [
      Class['stash::install'],
      File[$stash::webappdir],
      File[$stash::homedir]
    ],
  }
}
