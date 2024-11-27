require 'spec_helper'

describe 'stash' do
  describe 'stash::config' do
    context 'supported operating systems' do
      on_supported_os.each do |os, facts|
        context "on #{os} #{facts}" do
          let(:facts) do
            facts
          end

          context 'default params' do
            let(:params) do
              {
                version: '6.8.1',
                javahome: '/opt/java',
                tomcat_port: '7990'
              }
            end

            it do
              is_expected.not_to contain_file('/opt/stash/atlassian-bitbucket-6.8.1/bin/setenv.sh')
            end

            it { is_expected.not_to contain_file('/opt/stash/atlassian-bitbucket-6.8.1/bin/user.sh') }

            it do
              is_expected.not_to contain_file('/opt/stash/atlassian-bitbucket-6.8.1/conf/server.xml')
            end

            it do
              is_expected.not_to contain_file('/home/stash/shared/stash-config.properties')
            end

            it do
              is_expected.not_to contain_ini_setting('stash_httpport').with('value' => '7990')
            end
          end

          context 'stash 3.8.1' do
            let(:params) do
              {
                version: '3.8.1',
                product: 'stash',
                javahome: '/opt/java'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.8.1/bin/setenv.sh'). \
                with_content(%r{JAVA_HOME=/opt/java}).
                with_content(%r{^JVM_MINIMUM_MEMORY="256m"}).
                with_content(%r{^JVM_MAXIMUM_MEMORY="1024m"}).
                with_content(%r{^STASH_MAX_PERM_SIZE=256m}).
                with_content(%r{JAVA_OPTS="})
            end

            it { is_expected.to contain_file('/opt/stash/atlassian-stash-3.8.1/bin/user.sh') }

            it do
              is_expected.to contain_file('/home/stash/shared/server.xml').
                with_content(%r{<Connector port="7990"}).
                with_content(%r{path=""}).
                without_content(%r{proxyName}).
                without_content(%r{proxyPort}).
                without_content(%r{scheme})
            end

            it do
              is_expected.to contain_ini_setting('stash_httpport').with('value' => '7990')
            end

            it do
              is_expected.to contain_file('/home/stash/shared/stash-config.properties').
                with_content(%r{setup\.displayName=Bitbucket}).
                with_content(%r{setup.baseUrl=https://foo.example.com}).
                with_content(%r{setup\.sysadmin\.username=admin}).
                with_content(%r{setup\.sysadmin\.password=stash}).
                with_content(%r{setup\.sysadmin\.displayName=Stash Admin}).
                with_content(%r{setup\.sysadmin\.emailAddress=})
            end
          end

          context 'stash 3.8.1 with additional stash-config.properties values' do
            let(:params) do
              {
                version: '3.8.1',
                javahome: '/opt/java',
                config_properties: {
                  'aaaa' => 'bbbb',
                  'cccc' => 'dddd'
                }
              }
            end

            it do
              is_expected.to contain_file('/home/stash/shared/stash-config.properties').
                with_content(%r{^aaaa=bbbb$}).
                with_content(%r{^cccc=dddd$})
            end
          end

          context 'stash 3.7.0 with additional stash-config.properties values' do
            let(:params) do
              {
                version: '3.7.0',
                javahome: '/opt/java',
                config_properties: {
                  'aaaa' => 'bbbb',
                  'cccc' => 'dddd'
                }
              }
            end

            it do
              is_expected.not_to contain_file('/home/stash/shared/stash-config.properties').
                with_content(%r{^aaaa=bbbb$}).
                with_content(%r{^cccc=dddd$})
            end
          end

          context 'proxy settings' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                proxy: {
                  'scheme'    => 'https',
                  'proxyName' => 'stash.example.co.za',
                  'proxyPort' => '443'
                }
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/conf/server.xml'). \
                with_content(%r{proxyName = 'stash\.example\.co\.za'}).
                with_content(%r{proxyPort = '443'}).
                with_content(%r{scheme = 'https'})
            end
          end

          context 'stash 3.8.0' do
            let(:params) do
              {
                version: '3.8.0',
                javahome: '/opt/java'
              }
            end

            it do
              is_expected.not_to contain_file('/opt/stash/atlassian-stash-3.7.0/conf/server.xml')
              is_expected.to contain_file('/home/stash/shared/server.xml')
            end
          end

          context 'jvm_xms => 1G' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                jvm_xms: '1G'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/bin/setenv.sh').
                with_content(%r{^JVM_MINIMUM_MEMORY="1G"})
            end
          end

          context 'jvm_xmx => 4G' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                jvm_xmx: '4G'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/bin/setenv.sh').
                with_content(%r{^JVM_MAXIMUM_MEMORY="4G"})
            end
          end

          context 'jvm_permgen => 384m' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                jvm_permgen: '384m'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/bin/setenv.sh').
                with_content(%r{^STASH_MAX_PERM_SIZE=384m})
            end
          end

          context 'java_opts => "-Dhttp.proxyHost=proxy.example.co.za -Dhttp.proxyPort=8080"' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                java_opts: '-Dhttp.proxyHost=proxy.example.co.za -Dhttp.proxyPort=8080'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/bin/setenv.sh').
                with_content(%r{JAVA_OPTS="-Dhttp\.proxyHost=proxy\.example\.co\.za -Dhttp\.proxyPort=8080})
            end
          end

          context 'context_path => "stash"' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                context_path: '/stash'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/conf/server.xml').
                with_content(%r{path="/stash"})
            end
          end

          context 'ajp_port => "8009"' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                tomcat_port: '8009'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/conf/server.xml').
                with_content(%r{<Connector port="8009"})
            end
          end

          context 'tomcat_port => "7991"' do
            let(:params) do
              {
                version: '3.7.0',
                product: 'stash',
                javahome: '/opt/java',
                tomcat_port: '7991'
              }
            end

            it do
              is_expected.to contain_file('/opt/stash/atlassian-stash-3.7.0/conf/server.xml').
                with_content(%r{<Connector port="7991"})
            end

            it do
              is_expected.to contain_ini_setting('stash_httpport').with('value' => '7991')
            end
          end
        end
      end
    end
  end
end
