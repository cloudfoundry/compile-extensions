require 'spec_helper'
require 'open3'

describe 'download_dependency' do
  def run_download_dependency
    Open3.capture3("#{buildpack_directory}/compile-extensions/bin/download_dependency #{original_url} #{install_directory}")
  end

  let(:buildpack_directory) { Dir.mktmpdir }
  let(:install_directory) { Dir.mktmpdir }
  let!(:manifest) do
    File.open(File.join(buildpack_directory, 'manifest.yml'), 'w') do |file|
      file.write <<-MANIFEST
---
url_to_dependency_map:
  -
    match: .
    version: 0
    name: something

dependencies:
  -
    name: something
    version: 0
    uri: file://#{original_url}
    cf_stacks:
      - lucid64
    md5: #{md5}
      MANIFEST
    end
  end

  let(:original_url) do
    path = File.join(Dir.mktmpdir, 'something.txt')
    File.open(path, 'w') do |file|
      file.write 'something'
    end
    path
  end

  let(:md5) { Digest::MD5.file(original_url).hexdigest }

  before do
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    `cp -a #{base_dir} #{buildpack_directory}/compile-extensions`
  end

  context 'filename is in the manifest' do
    context 'When downloaded file has a valid checksum' do
      it 'downloads a uri to a specified directory' do
        run_download_dependency
        expect(File).to exist("#{install_directory}/something.txt")
      end
    end


    context 'When downloaded file has invalid checksum' do
      let(:md5) { Digest::MD5.hexdigest('something else') }

      it 'the process ends with the correct exit code' do
        _, _, status = run_download_dependency
        expect(status).not_to be_success
      end

      it 'File is not present at the specified directory' do
        run_download_dependency
        expect(File).not_to exist("#{install_directory}/something.txt")
      end

    end
  end

  context 'filename is not in the manifest' do
    let(:original_url) do
      path = File.join(Dir.mktmpdir, 'something_else.txt')
    end
    let(:md5) {''}

    it 'does not download the file to the specified directory' do
      run_download_dependency
      expect(File).not_to exist("#{install_directory}/something_else.txt")
    end
  end
end
