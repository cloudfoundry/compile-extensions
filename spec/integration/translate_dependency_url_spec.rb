require 'spec_helper'

describe 'translate_dependency_url' do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:original_url) { 'http://thing.com/file.txt' }
  let(:translated_url) { `./bin/translate_dependency_url #{original_url}` }

  before do
    ENV['BUILDPACK_PATH'] = tmp_dir
  end

  after do
    FileUtils.remove_entry tmp_dir
    ENV.delete('BUILDPACK_PATH')
  end

  context 'with a cache' do
    before do
      `mkdir #{tmp_dir}/dependencies`
    end

    specify do
      expect(translated_url).to eq("file://#{tmp_dir}/dependencies/http___thing.com_file.txt\n")
    end
  end

  context 'without a cache' do
    specify do
      expect(translated_url).to eq "#{original_url}\n"
    end
  end
end
