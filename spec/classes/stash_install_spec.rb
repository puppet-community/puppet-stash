require 'spec_helper'

describe 'stash' do
  describe 'stash::install' do
    context 'supported operating systems' do
      on_supported_os.each do |os, facts|
        context "on #{os} #{facts}" do
          let(:facts) do
            facts
          end
          let(:params) do
            {
              version: STASH_VERSION,
              javahome: '/opt/java'
            }
          end

          it 'deploys stash from archive' do
            is_expected.to contain_archive("/tmp/atlassian-bitbucket-#{STASH_VERSION}.tar.gz").
              with('extract_path'  => "/opt/stash/atlassian-bitbucket-#{STASH_VERSION}",
                   'source'        => "https://product-downloads.atlassian.com/software/stash/downloads/atlassian-bitbucket-#{STASH_VERSION}.tar.gz",
                   'creates'       => "/opt/stash/atlassian-bitbucket-#{STASH_VERSION}/bin",
                   'user'          => 'stash',
                   'group'         => 'stash',
                   'checksum_type' => 'md5')
          end

          it 'manages the stash home directory' do
            is_expected.to contain_file('/home/stash').
              with('ensure' => 'directory',
                   'owner' => 'stash',
                   'group' => 'stash')
          end

          it 'manages the stash application directory' do
            is_expected.to contain_file("/opt/stash/atlassian-bitbucket-#{STASH_VERSION}").
              with('ensure' => 'directory',
                   'owner' => 'stash',
                   'group' => 'stash')
          end

          context 'when managing the user and group inside the module' do
            let(:params) do
              {
                javahome: '/opt/java',
                manage_usr_grp: true
              }
            end

            context 'when no user or group are specified' do
              it { is_expected.to contain_user('stash').with_shell('/bin/bash') }
              it { is_expected.to contain_group('stash') }
            end

            context 'when a user and group is specified' do
              let(:params) do
                {
                  javahome: '/opt/java',
                  user: 'mystashuser',
                  group: 'mystashgroup'
                }
              end

              it { is_expected.to contain_user('mystashuser') }
              it { is_expected.to contain_group('mystashgroup') }
            end
          end

          context 'when managing the user and group outside the module' do
            context 'when no user or group are specified' do
              let(:params) do
                {
                  javahome: '/opt/java',
                  manage_usr_grp: false
                }
              end

              it { is_expected.not_to contain_user('stash') }
              it { is_expected.not_to contain_group('stash') }
            end
          end

          context 'overwriting params' do
            let(:params) do
              {
                version: STASH_VERSION,
                javahome: '/opt/java',
                installdir: '/custom/stash',
                homedir: '/random/homedir',
                user: 'foo',
                group: 'bar',
                uid: 333,
                gid: 444,
                download_url: 'http://downloads.atlassian.com/',
                deploy_module: 'staging'
              }
            end

            it do
              is_expected.to contain_staging__file("atlassian-bitbucket-#{STASH_VERSION}.tar.gz").
                with('source' => "http://downloads.atlassian.com//atlassian-bitbucket-#{STASH_VERSION}.tar.gz")
              is_expected.to contain_staging__extract("atlassian-bitbucket-#{STASH_VERSION}.tar.gz").
                with('target'  => "/custom/stash/atlassian-bitbucket-#{STASH_VERSION}",
                     'user'    => 'foo',
                     'group'   => 'bar',
                     'creates' => "/custom/stash/atlassian-bitbucket-#{STASH_VERSION}/bin").
                that_comes_before('File[/random/homedir]').
                that_requires('File[/custom/stash]').
                that_notifies("Exec[chown_/custom/stash/atlassian-bitbucket-#{STASH_VERSION}]")
            end

            it do
              is_expected.to contain_user('foo').with('home' => '/random/homedir',
                                                      'shell' => '/bin/bash',
                                                      'uid' => 333,
                                                      'gid' => 444)
            end

            it { is_expected.to contain_group('bar') }

            it 'manages the stash home directory' do
              is_expected.to contain_file('/random/homedir').with('ensure' => 'directory',
                                                                  'owner' => 'foo',
                                                                  'group' => 'bar')
            end
          end
        end
      end
    end
  end
end
