# == Class: stash
#
# Full description of class stash here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { stash:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class stash(

  # JVM Settings
  $javahome     = undef,
  $jvm_xms      = '256m',
  $jvm_xmx      = '1024m',
  $jvm_optional = '-XX:-HeapDumpOnOutOfMemoryError',
  $jvm_support_recommended_args = '',
  $java_opts    = '',

  # Stash Settings
  $version      = '3.2.4',
  $product      = 'stash',
  $format       = 'tar.gz',
  $installdir   = '/opt/stash',
  $homedir      = '/home/stash',
  $user         = 'stash',
  $group        = 'stash',
  $uid          = undef,
  $gid          = undef,

  # Database Settings
  $dbuser       = 'stash',
  $dbpassword   = 'password',
  $dburl        = 'jdbc:postgresql://localhost:5432/stash',
  $dbdriver     = 'org.postgresql.Driver',

  # Misc Settings
  $downloadURL  = 'http://www.atlassian.com/software/stash/downloads/binary/',

  # Manage service
  $manage_service  = true,

  # Reverse https proxy
  $proxy = {},

  # Git version
  $git_version = 'installed'
) {

  $webappdir    = "${installdir}/atlassian-${product}-${version}"

  anchor { 'stash::start':
  } ->
  class { 'stash::install':
    webappdir => $webappdir
  } ->
  class { 'stash::config':
  } ~>
  class { 'stash::service':
  } ->
  anchor { 'stash::end': }

}
