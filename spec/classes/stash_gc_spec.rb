require 'spec_helper'

describe 'stash::gc', type: :class do
  context 'supported operating systems' do
    let(:pre_condition) { "class{'stash': javahome => '/opt/java', }" }

    on_supported_os.each do |os, facts|
      context "on #{os} #{facts}" do
        let(:facts) do
          facts
        end

        regexp_lt  = %r{home/stash/data/repositories}
        regexp_gte = %r{home/stash/shared/data/repositories}

        file = '/usr/local/bin/git-gc.sh'

        it { is_expected.to contain_file(file) }

        context 'with stash version less than 3.2.0' do
          let(:facts) do
            facts.merge(stash_version: '3.1.99')
          end

          it do
            is_expected.to contain_file(file).
              with_content(regexp_lt)
          end
        end

        context 'with stash version greater than 3.2.0' do
          it do
            is_expected.to contain_file(file).
              with_content(regexp_gte)
          end
        end

        context 'with stash equal to 3.2' do
          let(:facts) do
            facts.merge(stash_version: '3.2.0')
          end

          it do
            is_expected.to contain_file(file).
              with_content(regexp_gte)
          end
        end
      end
    end
  end
end
