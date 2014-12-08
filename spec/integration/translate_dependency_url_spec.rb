require 'spec_helper'

describe 'translate_dependency_url' do
  def run_translate
    binary_file = File.expand_path('../../../bin/translate_dependency_url', __FILE__)
    `cd #{buildpack_dir} && #{binary_file} #{original_url}`
  end

  let(:buildpack_dir) { Dir.mktmpdir }
  let(:original_url) { 'http://thing.com/file.txt' }

  after do
    FileUtils.remove_entry buildpack_dir
  end

  context 'with a cache' do
    before do
      `mkdir #{buildpack_dir}/dependencies`
    end

    specify do
      translated_url = run_translate

      expect(translated_url).to eq("file://#{buildpack_dir}/dependencies/http___thing.com_file.txt\n")
    end
  end

  context 'without a cache' do
    specify do
      translated_url = run_translate

      expect(translated_url).to eq "#{original_url}\n"
    end
  end
end
