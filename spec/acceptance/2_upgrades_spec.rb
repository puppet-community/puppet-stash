require 'spec_helper_acceptance'

download_url = ENV['download_url'] if ENV['download_url']
download_url = if ENV['download_url']
                 ENV['download_url']
               else
                 'undef'
               end

# We add the sleeps everywhere to give stash enough
# time to install/upgrade/run migration tasks/start

describe 'stash' do
  it 'upgrades to 4.0.2 with defaults and context /stash1' do
    pp_update = <<-EOS
      if versioncmp($::puppetversion,'3.6.1') >= 0 {
        $allow_virtual_packages = hiera('allow_virtual_packages',false)
        Package {
          allow_virtual => $allow_virtual_packages,
        }
      }
      $jh = $osfamily ? {
        default => '/opt/java',
      }
      class { 'stash':
        version       => '3.11.4',
        checksum      => '8e6f51c250219dc6a85a310935e4a281',
        download_url  => #{download_url},
        javahome      => $jh,
        context_path  => '/stash1',
      }
      include stash::facts
    EOS
    apply_manifest(pp_update, catch_failures: true)
    shell 'wget -q --tries=20 --retry-connrefused --read-timeout=10 localhost:7990/stash1'
    sleep 180
    apply_manifest(pp_update, catch_failures: true)
    shell 'wget -q --tries=20 --retry-connrefused --read-timeout=10 localhost:7990/stash1', acceptable_exit_codes: [0]
    sleep 120
    apply_manifest(pp_update, catch_changes: true)
    shell 'wget -q --tries=20 --retry-connrefused --read-timeout=10 localhost:7990/stash1', acceptable_exit_codes: [0]
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
  end

  describe user('stash') do
    it { is_expected.to belong_to_group 'stash' }
  end

  describe user('stash') do
    it { is_expected.to have_login_shell '/bin/bash' }
  end

  describe command('curl http://localhost:7990/stash1/setup') do
    its(:stdout) { is_expected.to match(%r{This is the base URL of this installation of Stash}) }
  end

  describe command('facter -p stash_version') do
    its(:stdout) { is_expected.to match(%r{3\.11\.4}) }
  end
end
