require 'spec_helper'

module CompileExtensions
  describe Dependencies do

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
                  'uri' => 'my_dog_has_fleas-v1'
              },
              {
                  'version' => 'two',
                  'name' => 'green',
                  'uri' => 'i_do_not_like_green_eggs_and_ham-v2'
              },
              {
                  'version' => '1.9.3',
                  'name' => 'ruby',
                  'uri' => 'http://cf.buildpacks.com/ruby-1.9.3.tgz'
              }
          ]
      }
    }

    subject(:dependencies) { CompileExtensions::Dependencies.new(manifest) }

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
        let(:original_url) { 'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/cedar/ruby-1.9.3.tgz' }

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
  end
end
