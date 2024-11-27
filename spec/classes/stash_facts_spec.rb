require 'spec_helper'

describe 'stash::facts', type: :class do
  context 'supported operating systems' do
    let(:pre_condition) { "class{'stash': javahome => '/opt/java', }" }

    on_supported_os.each do |os, facts|
      context "on #{os} #{facts}" do
        let(:facts) do
          facts
        end

        regexp_rubypath = %r{/opt/puppetlabs/puppet/bin/ruby}
        external_fact_file = '/etc/facter/facts.d/stash_facts.rb'

        it { is_expected.to contain_file(external_fact_file) }

        # Test puppet enterprise shebang generated correctly
        context 'with puppet enterprise' do
          let(:facts) do
            facts.merge(puppetversion: '3.4.3 (Puppet Enterprise 3.2.1)')
          end

          it do
            is_expected.to contain_file(external_fact_file). \
              with_content(regexp_rubypath)
          end
        end

        ## Test puppet oss shebang generated correctly
        context 'with puppet oss' do
          it do
            is_expected.to contain_file(external_fact_file). \
              with_content(regexp_rubypath).
              with_content(%r{7990/rest/api/})
          end
        end

        context 'with context' do
          let(:params) do
            { context_path: '/stash' }
          end

          it do
            is_expected.to contain_file(external_fact_file). \
              with_content(%r{7990/stash/rest/api/})
          end
        end
      end
    end
  end
end
