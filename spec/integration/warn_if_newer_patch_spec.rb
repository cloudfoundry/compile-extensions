require 'spec_helper'
require 'fileutils'
require 'open3'

describe 'warn_if_newer_patch' do
  def run_warn_if_newer_patch(url)
    Open3.capture3("./bin/warn_if_newer_patch #{url} #{manifest_location}")
  end

  let(:buildpack_directory)  { Dir.mktmpdir }
  let(:manifest_location)    { File.join(buildpack_directory, 'manifest.yml') }

  let(:manifest_contents) do
  <<-MANIFEST
---
url_to_dependency_map:
  - match: .*dependency\.(.*)\.txt
    version: $1
    name: dependency

dependencies:
  - name: dependency
    version: 1.2.3
    uri: file://dependency.1.2.3.txt
    md5: 123456
    cf_stacks:
      - cflinuxfs2
  - name: dependency
    version: 1.2.4
    uri: file://dependency.1.2.4.txt
    md5: 987654
    cf_stacks:
      - cflinuxfs2
      MANIFEST
  end

  before do
    File.write(manifest_location, manifest_contents)
  end

  after do
    FileUtils.rm_rf(buildpack_directory)
  end

  context 'the dependency is found in the manifest' do
    context 'the version is the latest patch' do
      let(:dependency_url) { 'https://example.com/dependency.1.2.4.txt' }

      it 'does not write to STDOUT' do
        stdout, _, _ = run_warn_if_newer_patch(dependency_url)
        expect(stdout).to eq ''
      end
    end

    context 'the version is not the latest patch' do
      let(:dependency_url) { 'https://example.com/dependency.1.2.3.txt' }

      it 'write a warning telling the user to upgrade' do
        patch_warning = "**WARNING** A newer version of dependency is available in this buildpack. " +
                        "Please adjust your app to use version 1.2.4 instead of version 1.2.3 as soon as possible. " +
                        "Old versions of dependency are only provided to assist in migrating to newer versions."

        stdout, _, _ = run_warn_if_newer_patch(dependency_url)
        expect(stdout.chomp).to include patch_warning
      end

    end
  end

  context 'the dependency is not found in the manifest' do
    let(:dependency_url) { 'https://example.com/another_thing.1.2.4.txt' }

    it 'does not write to STDOUT' do
      stdout, _, _ = run_warn_if_newer_patch(dependency_url)
      expect(stdout).to eq ''
    end
  end
end
