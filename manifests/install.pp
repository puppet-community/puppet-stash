# == Class: stash::install
#
# This installs the stash module. See README.md for details
#
class stash::install(
  $version        = $stash::version,
  $product        = $stash::product,
  $format         = $stash::format,
  $installdir     = $stash::installdir,
  $homedir        = $stash::homedir,
  $manage_usr_grp = $stash::manage_usr_grp,
  $user           = $stash::user,
  $group          = $stash::group,
  $uid            = $stash::uid,
  $gid            = $stash::gid,
  $git_version    = $stash::git_version,
  $repoforge      = $stash::repoforge,
  $download_url   = $stash::download_url,
  $deploy_module  = $stash::deploy_module,
  $git_manage     = $stash::git_manage,
  $dburl          = $stash::dburl,
  $checksum       = $stash::checksum,
  $mysqlc_manage  = $stash::mysql_connector_manage,
  $mysqlc_version = $stash::mysql_connector_version,
  $mysqlc_install = $stash::mysql_connector_installdir,
  $webappdir,
  ) {

  include '::archive'
  
  if $git_manage {
    if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
      validate_bool($repoforge)
      # If repoforge is not enabled by default, enable it
      # but only allow git to be installed from it.
      if ! defined(Class['repoforge']) and $repoforge {
        class { '::repoforge':
          enabled     => [ 'extras', ],
          includepkgs => {
            'extras' => 'git,perl-Git',
          },
          before      => Package['git'],
        } ~>
        exec { "${stash::product}_clean_yum_metadata":
          command     => '/usr/bin/yum clean metadata',
          refreshonly => true,
        } ~>
        # Git may already have been installed, so lets update it to a 
        # supported version.
        exec { "${stash::product}_upgrade_git":
          command     => '/usr/bin/yum -y upgrade git',
          onlyif      => '/bin/rpm -qa git',
          refreshonly => true,
        }
      }
    }
    package { 'git':
      ensure => $git_version,
    }
  }

  if $manage_usr_grp {
    #Manage the group in the module
    group { $group:
      ensure => present,
      gid    => $gid,
    }
    #Manage the user in the module
    user { $user:
      comment          => 'Stash daemon account',
      shell            => '/bin/bash',
      home             => $homedir,
      password         => '*',
      password_min_age => '0',
      password_max_age => '99999',
      managehome       => true,
      uid              => $uid,
      gid              => $gid,
    }
  }

  if ! defined(File[$installdir]) {
    file { $installdir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
    }
  }

  # Deploy files using either staging or deploy modules.
  $file = "atlassian-${product}-${version}.${format}"

  if ! defined(File[$webappdir]) {
    file { $webappdir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
    }
  }

  case $deploy_module {
    'staging': {
      require staging
      staging::file { $file:
        source  => "${download_url}/${file}",
        timeout => 1800,
      } ->
      staging::extract { $file:
        target  => $webappdir,
        creates => "${webappdir}/conf",
        strip   => 1,
        user    => $user,
        group   => $group,
        notify  => Exec["chown_${webappdir}"],
        before  => File[$homedir],
        require => [
          File[$installdir],
          User[$user],
          File[$webappdir] ],
      }
    }
    'archive': {
      archive { "/tmp/${file}":
        ensure        => present,
        extract       => true,
        extract_path  => $installdir,
        source        => "${download_url}/${file}",
        creates       => "${webappdir}/conf",
        cleanup       => true,
        checksum_type => 'md5',
        checksum      => $checksum,
        user          => $user,
        group         => $group,
        before        => File[$webappdir],
        require       => [
          File[$installdir],
          User[$user],
        ],
      }
    }
    default: {
      fail('deploy_module parameter must equal "archive" or staging""')
    }
  }

  file { $homedir:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    require => User[$user],
  } ->

  exec { "chown_${webappdir}":
    command     => "/bin/chown -R ${user}:${group} ${webappdir}",
    refreshonly => true,
    subscribe   => [ User[$user], File[$webappdir] ],
  }

  if $dburl =~ /jdbc\.url=jdbc:mysql:/ and $mysqlc_manage {
    class { '::mysql_java_connector':
      links      => "${webappdir}/lib",
      version    => $mysqlc_version,
      installdir => $mysqlc_install,
    }
  }

}
