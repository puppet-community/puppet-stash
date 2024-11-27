require 'spec_helper_acceptance'

# It is sometimes faster to host jira / java files on a local webserver.
# Set environment variable download_url to use local webserver
# export download_url = 'http://10.0.0.XXX/'
download_url = ENV['download_url'] if ENV['download_url']
download_url = ENV['download_url'] || 'undef'
java_url = if download_url == 'undef'
             'http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz'
           else
             download_url
           end

# We add the sleeps everywhere to give stash enough
# time to install/upgrade/run migration tasks/start

describe 'stash' do
  it 'installs with defaults and context /stash1' do
    pp = <<-EOS
      $jh = $osfamily ? {
        default => '/opt/java',
      }
      if versioncmp($::puppetversion,'3.6.1') >= 0 {
        $allow_virtual_packages = hiera('allow_virtual_packages',false)
        Package {
          allow_virtual => $allow_virtual_packages,
        }
      }
      class { 'postgresql::globals':
        manage_package_repo => true,
        version             => '9.4',
      }->
      class { 'postgresql::server': } ->
      postgresql::server::db { 'stash':
        user     => 'stash',
        password => postgresql_password('stash', 'password'),
      } ->
      file { $jh:
        ensure => 'directory',
      } ->
      archive { '/tmp/jdk-8u45-linux-x64.tar.gz':
        ensure          => present,
        extract         => true,
        extract_command => 'tar xfz %s --strip-components=1',
        extract_path    => $jh,
        source          => "#{java_url}",
        creates         => "${jh}/bin",
        cleanup         => true,
        cookie          => 'oraclelicense=accept-securebackup-cookie',
      } ->
      class { 'stash':
        version          => '3.9.2',
        checksum         => 'a80cbed70843e9a394867adc800f7704',
        download_url     => #{download_url},
        javahome         => $jh,
        context_path     => '/stash1',
        backupclient_url => #{download_url},
      }
      include ::stash::facts
    EOS
    apply_manifest(pp, catch_failures: true)
    sleep 180
    shell 'wget -q --tries=20 --retry-connrefused --read-timeout=10 localhost:7990/stash1'
    apply_manifest(pp, catch_failures: true)
    sleep 180
    shell 'wget -q --tries=20 --retry-connrefused --read-timeout=10 localhost:7990/stash1', acceptable_exit_codes: [0]
    apply_manifest(pp, catch_changes: true)
  end

  describe process('java') do
    it { is_expected.to be_running }
  end

  describe port(7990) do
    it { is_expected.to be_listening }
  end

  describe package('git') do
    it { is_expected.to be_installed }
  end

  describe service('stash') do
    it { is_expected.to be_enabled }
  end

  describe user('stash') do
    it { is_expected.to exist }
    it { is_expected.to belong_to_group 'stash' }
    it { is_expected.to have_login_shell '/bin/bash' }
  end

  describe command('curl http://localhost:7990/stash1/setup') do
    its(:stdout) { is_expected.to match(%r{This is the base URL of this installation of Stash}) }
  end

  describe command('facter -p stash_version') do
    its(:stdout) { is_expected.to match(%r{3\.9\.2}) }
  end

  describe cron do
    it { is_expected.to have_entry('0 5 * * * /opt/java/bin/java -Dstash.password="password" -Dstash.user="admin" -Dstash.baseUrl="http://localhost:7990" -Dstash.home=/home/stash -Dbackup.home=/opt/stash-backup/archives -jar /opt/stash-backup/stash-backup-client-1.9.1/stash-backup-client.jar').with_user('stash') }
  end

  describe file('/opt/stash-backup/stash-backup-client-1.9.1/stash-backup-client.jar') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'stash' }
  end
end
