require 'yaml'
require 'spec_helper'

module CompileExtensions

  describe Dependencies do
    subject(:dependencies) { CompileExtensions::Dependencies.new(manifest) }

    describe "stack filtering" do
      let(:manifest) do
        {
          'url_to_dependency_map' => [
            {
              'match' => /first_stack_widget/,
              'version' => '1',
              'name' => 'first_stack_widget'
            },
            {
              'match' => /any_stack_widget/,
              'version' => '1',
              'name' => 'any_stack_widget'
            },
            {
              'match' => /both_stacks_widget/,
              'version' => '1',
              'name' => 'both_stacks_widget'
            },
            {
              'match' => /cflinuxfs2_stack_widget/,
              'version' => '1',
              'name' => 'cflinuxfs2_stack_widget'
            },
          ],
          'dependencies' => [
            {
              'version' => '1',
              'name' => 'first_stack_widget',
              'uri' => 'first_stack_only',
              'cf_stacks' => ['first']
            },
            {
              'version' => '1',
              'name' => 'both_stacks_widget',
              'uri' => 'both_stacks_only',
              'cf_stacks' => ['first', 'second']
            },
            {
              'version' => '1',
              'name' => 'cflinuxfs2_stack_widget',
              'uri' => 'cflinuxfs2_stack_dep',
              'cf_stacks' => ['cflinuxfs2']
            },

          ]
        }
      end

      let(:matching_dependency) { dependencies.find_matching_dependency(original_url) }

      context 'environment uses first stack' do
        before do
          ENV['CF_STACK'] = 'first'
        end

        context 'dependency that only matches the first stack' do
          let(:original_url) { 'first_stack_widget' }

          specify do
            expect(matching_dependency['uri']).to eql('first_stack_only')
          end
        end
      end

      context 'environment uses second stack' do
        before do
          ENV['CF_STACK'] = 'second'
        end

        context 'dependency that only matches the first stack' do
          let(:original_url) { 'first_stack_widget' }

          specify do
            expect(matching_dependency).to be_nil
          end
        end

        context 'dependency that will match first or second stack' do
          let(:original_url) { 'both_stacks_widget' }

          specify do
            expect(matching_dependency['uri']).to eql('both_stacks_only')
          end
        end
      end

      context 'environment does not tell us what stack it uses' do
        before do
          ENV.delete('CF_STACK')
        end

        context 'dependency that matches the cflinuxfs2 stack' do
          let(:original_url) { 'cflinuxfs2_stack_widget' }

          specify do
            expect(matching_dependency['uri']).to eql('cflinuxfs2_stack_dep')
          end
        end

        context 'dependency that does not match the cflinuxfs2 stack' do
          let(:original_url) { 'first_stack_widget' }

          specify do
            expect(matching_dependency).to be_nil
          end
        end
      end
    end

    describe "Dependency Mapping" do
      let(:manifest) {
        {
          'url_to_dependency_map' => [
            {
              'match' => /frontdoor/,
              'version' => 'two',
              'name' => 'green'
            },
            {
              'match' => /backdoor/,
              'version' => 'one',
              'name' => 'my_dog'
            },
            {
              'match' => /\/(ruby)-(\d+).(\d+).(\d+).tgz/,
              'version' => '$2.$3.$4',
              'name' => '$1'
            }
          ],
          'dependencies' => [
            {
              'version' => 'one',
              'name' => 'my_dog',
              'uri' => 'my_dog_has_fleas-v1',
              'cf_stacks' => ['cflinuxfs2']
            },
            {
              'version' => 'two',
              'name' => 'green',
              'uri' => 'i_do_not_like_green_eggs_and_ham-v2',
              'cf_stacks' => ['cflinuxfs2']
            },
            {
              'version' => '1.9.3',
              'name' => 'ruby',
              'uri' => 'http://cf.buildpacks.com/ruby-1.9.3.tgz',
              'cf_stacks' => ['cflinuxfs2']
            },
            {
              'version' => 1.9,
              'name' => 'ruby',
              'uri' => 'http://cf.buildpacks.com/ruby-1.9.tgz',
              'cf_stacks' => ['cflinuxfs2']
            }
          ]
        }
      }


      describe 'find matching dependency hash' do
        let(:matching_dependency) { dependencies.find_matching_dependency(original_url) }

        context 'a url that should match my_dog_has_fleas-v1' do
          let(:original_url) { 'https://google.com/backdoor' }

          specify do
            expect(matching_dependency['uri']).to eql('my_dog_has_fleas-v1')
            expect(matching_dependency['version']).to eql('one')
            expect(matching_dependency['name']).to eql('my_dog')
          end
        end

        context 'a url that should match i_do_not_like_green_eggs_and_ham-v2' do
          let(:original_url) { 'https://google.com/frontdoor' }

          specify do
            expect(matching_dependency['uri']).to eql('i_do_not_like_green_eggs_and_ham-v2')
            expect(matching_dependency['version']).to eql('two')
            expect(matching_dependency['name']).to eql('green')
          end
        end

        context 'a url that should match a versioned ruby dependency' do
          let(:original_url) { 'https://s3-external-1.amazonaws.com/ruby-buildpack/stack-name/ruby-1.9.3.tgz' }

          specify do
            expect(matching_dependency['uri']).to eql('http://cf.buildpacks.com/ruby-1.9.3.tgz')
            expect(matching_dependency['version']).to eql('1.9.3')
            expect(matching_dependency['name']).to eql('ruby')
          end
        end

        context 'for a url that has no matches in url_to_dependencies_map' do
          let(:original_url) { 'https://notthere.com' }

          specify do
            expect(matching_dependency).to be_nil
          end
        end

      end

      describe 'find matching dependency translated url' do
        let(:translated_url) { dependencies.find_translated_url(original_url) }

        context 'a matching dependency' do
          let(:original_url) { 'https://google.com/backdoor' }

          specify do
            expect(translated_url).to eql('my_dog_has_fleas-v1')
          end
        end

        context 'no matching dependency' do
          let(:original_url) { 'https://notthere.com' }

          specify do
            expect(translated_url).to be_nil
          end
        end
      end

      describe 'returning versions on a similar dependency' do
        let(:versions) { dependencies.valid_versions('name' => 'ruby') }

        it 'returns a sorted list of versions' do
          expect(versions).to eq ['1.9.3', '1.9']
        end
      end
    end

    describe '#find_dependency_by_name' do
      let(:manifest_contents) do
        <<-MANIFEST
          dependencies:
          - name: node
            version: 4.8.2
            uri: https://buildpacks.cloudfoundry.org/dependencies/node/node-4.8.2-linux-x64-09d53abc.tgz
            md5: 09d53abca4f08cf63b9eb88b7175266f
            cf_stacks:
            - cflinuxfs2
          - name: node
            version: 4.8.3
            uri: https://buildpacks.cloudfoundry.org/dependencies/node/node-4.8.3-linux-x64-0622641b.tgz
            md5: 0622641b64386fdfcaa82da4987a1105
            cf_stacks:
            - cflinuxfs2
        MANIFEST
      end
      let(:manifest)   { YAML.load(manifest_contents) }
      let(:stack) { 'cflinuxfs2' }
      before do
        ENV['CF_STACK'] = stack
      end

      subject { dependencies.find_dependency_by_name dependency_name, dependency_version }

      context 'correct name and stack' do
        let(:dependency_name) { 'node' }

        context 'version 4.8.2' do
          let(:dependency_version) { '4.8.2' }
          it 'returns the requested version' do
            expect(subject['uri']).to eq 'https://buildpacks.cloudfoundry.org/dependencies/node/node-4.8.2-linux-x64-09d53abc.tgz'
          end
        end

        context 'version 4.8.3' do
          let(:dependency_version) { '4.8.3' }
          it 'returns the requested version' do
            expect(subject['uri']).to eq 'https://buildpacks.cloudfoundry.org/dependencies/node/node-4.8.3-linux-x64-0622641b.tgz'
          end
        end
      end

      context 'incorrect name' do
        let(:dependency_name) { 'ruby' }
        let(:dependency_version) { '4.8.2' }
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'incorrect stack' do
        let(:stack) { 'other' }
        let(:dependency_name) { 'node' }
        let(:dependency_version) { '4.8.2' }
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end

    describe '#newest_patch_version' do
      context 'the dependency versions are well formed' do
        let(:manifest_contents) do
        <<-MANIFEST
dependencies:
- name: ruby
  version: 2.3.2
- name: ruby
  version: 2.3.3
- name: ruby
  version: 2.2.5
- name: ruby
  version: 2.2.6
- name: ruby
  version: 2.1.9
- name: ruby
  version: 2.1.8
MANIFEST
        end
        let(:manifest)   { YAML.load(manifest_contents) }
        let(:dependency) { 'override' }

        subject { dependencies.newest_patch_version dependency }

        context 'there is a newer patch version' do
          let(:dependency) { {'name' => 'ruby', 'version' => '2.2.5'}  }

          it 'returns the newer version' do
            expect(subject).to eq '2.2.6'
          end
        end

        context 'there is not a newer patch version' do
          let(:dependency) { {'name' => 'ruby', 'version' => '2.1.9'}  }

          it 'returns the same version' do
            expect(subject).to eq '2.1.9'
          end
        end
      end

      context 'some dependency versions are pre-release' do
        let(:manifest_contents) do
        <<-MANIFEST
dependencies:
- name: dotnet
  version: 1.0.0-preview2-003156
- name: dotnet
  version: 1.0.0-preview2-003131
- name: dotnet
  version: 1.0.0-preview4-004233
- name: dotnet
  version: 1.0.0
- name: dotnet
  version: 1.0.0-preview2-1-003177
- name: dotnet
  version: 1.0.0-preview3-004056
MANIFEST
        end
        let(:manifest)   { YAML.load(manifest_contents) }
        let(:dependency) { {'name' => 'dotnet', 'version' => '1.0.0-preview2-1-003177'}  }

        subject { dependencies.newest_patch_version dependency }

        it 'returns the latest version' do
          expect(subject).to eq '1.0.0'
        end
      end

      context 'the dependency is JRuby' do
        let(:manifest_contents) do
        <<-MANIFEST
dependencies:
- name: jruby
  version: ruby-1.9.3-jruby-1.7.26
- name: jruby
  version: ruby-2.0.0-jruby-1.7.26
- name: jruby
  version: ruby-2.3.1-jruby-9.1.5.0
- name: jruby
  version: ruby-2.3.0-jruby-9.1.2.0
MANIFEST
        end
        let(:manifest)   { YAML.load(manifest_contents) }
        let(:dependency) { {'name' => 'jruby', 'version' => 'ruby-2.3.0-jruby-9.1.2.0'}  }

        subject { dependencies.newest_patch_version dependency }

        it 'uses the jruby version to make the determination' do
          expect(subject).to eq 'ruby-2.3.1-jruby-9.1.5.0'
        end
      end

    end
  end
end
