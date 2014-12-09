require 'spec_helper'
require 'open3'

describe 'translate_dependency_url' do
  def run_translate
    binary_file = File.expand_path('../../../bin/translate_dependency_url', __FILE__)
    Open3.capture3("cd #{buildpack_dir} && #{binary_file} #{original_url}")
  end

  let(:buildpack_dir) { Dir.mktmpdir }

  let(:manifest) {
    <<-MANIFEST
---
dependencies:
  -
    original: http://thing.com/file.txt
    xlated: http://thong.co.nz/file.txt
  -
    original: http://place.net/a_file.zip
    xlated: https://another_location/a_file_elsewhere.zip
    MANIFEST
  }

  before do
    File.open(File.join(buildpack_dir, 'manifest.yml'), 'w') do |file|
      file.puts manifest
    end
  end

  after do
    FileUtils.remove_entry buildpack_dir
  end

  context 'with a cache' do
    context 'when the url is defined in the manifest' do
      let(:original_url) { 'http://place.net/a_file.zip' }

      before do
        `mkdir #{buildpack_dir}/dependencies`
      end

      specify do
        translated_url, stderr, _ = run_translate
        puts stderr

        expect(translated_url).to eq("file://#{buildpack_dir}/dependencies/https___another_location_a_file_elsewhere.zip\n")
      end
    end
  end

  context 'without a cache' do
    context 'when the url is defined in the manifest' do
      let(:original_url) { 'http://thing.com/file.txt' }

      specify do
        translated_url, _, _ = run_translate

        expect(translated_url).to eq "http://thong.co.nz/file.txt\n"
      end
    end

    context 'when the url is not defined in the manifest' do
      let(:original_url) { 'http://i_r.not/here' }

      specify do
        translated_url, _, status = run_translate

        expect(translated_url).to eq "DEPENDENCY_MISSING_IN_MANIFEST: #{original_url}\n"
        expect(status).not_to be_success
      end
    end
  end
end
