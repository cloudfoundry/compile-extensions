require 'spec_helper'

module CompileExtensions
  describe Dependencies do

    let(:manifest) {
      {
          'dependencies' => [
              {
                  'original' => 'https://google.com/backdoor',
                  'xlated' => 'my_dog_has_fleas'
              },
              {
                  'original' => 'https://google.com/frontdoor',
                  'xlated' => 'i_do_not_like_green_eggs_and_ham'
              }
          ]
      }
    }

    subject(:dependencies) { CompileExtensions::Dependencies.new(manifest) }

    describe 'find matching dependency hash' do
      let(:matching_dependency) { dependencies.find_matching_dependency(original_url) }

      context 'a key that should match the first item' do
        let(:original_url) { 'https://google.com/backdoor' }

        specify do
          expect(matching_dependency['original']).to eql('https://google.com/backdoor')
          expect(matching_dependency['xlated']).to eql('my_dog_has_fleas')
        end
      end

      context 'a key that should match another item' do
        let(:original_url) { 'https://google.com/frontdoor' }

        specify do
          expect(matching_dependency['original']).to eql('https://google.com/frontdoor')
          expect(matching_dependency['xlated']).to eql('i_do_not_like_green_eggs_and_ham')
        end
      end

    end

    describe 'find matching dependency translated url' do
      let(:translated_url) { dependencies.find_translated_dependency(original_url) }

      context 'a matching dependency' do
        let(:original_url) { 'https://google.com/backdoor' }

        specify do
          expect(translated_url).to eql('my_dog_has_fleas')
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
