require 'spec_helper'
require 'fileutils'
require 'open3'

describe 'warn_if' do
  def run_warn_if_newer_patch(url)
    Open3.capture3("./bin/warn_if_newer_patch #{url} #{manifest_location}")
  end
  let(:stdout) do
    stdout, _, _ = run_warn_if_newer_patch(dependency_url)
    stdout.chomp
  end
  let(:stderr) do
    _, stderr, _ = run_warn_if_newer_patch(dependency_url)
    stderr.chomp
  end

  let(:buildpack_directory)  { Dir.mktmpdir }
  let(:manifest_location)    { File.join(buildpack_directory, 'manifest.yml') }
  before { File.write(manifest_location, manifest_contents) }
  after { FileUtils.rm_rf(buildpack_directory) }

  describe 'Newer Patch' do
    let(:manifest_contents) do
      <<-MANIFEST
---
url_to_dependency_map:
  - match: .*dependency\.(.*)\.txt
    version: $1
    name: dependency
  - match: .*node\.(.*)\.txt
    version: $1
    name: node

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
  - name: node
    version: 4.5.0
    uri: file://node.4.5.0.txt
    md5: 111111
    cf_stacks:
      - cflinuxfs2
  - name: node
    version: 4.6.0
    uri: file://node.4.6.0.txt
    md5: 222222
    cf_stacks:
      - cflinuxfs2
      MANIFEST
    end

    context 'the dependency is found in the manifest' do
      context 'the version is the latest patch' do
        let(:dependency_url) { 'https://example.com/dependency.1.2.4.txt' }

        it 'does not write to STDOUT' do
          expect(stdout).to eq ''
        end
      end

      context 'the version is not the latest patch' do
        let(:dependency_url) { 'https://example.com/dependency.1.2.3.txt' }

        it 'write a warning telling the user to upgrade' do
          patch_warning = "**WARNING** A newer version of dependency is available in this buildpack. " +
            "Please adjust your app to use version 1.2.4 instead of version 1.2.3 as soon as possible. " +
            "Old versions of dependency are only provided to assist in migrating to newer versions."

          expect(stdout.chomp).to include patch_warning
        end
      end

      context 'the dependency is node' do
        context 'the version is the latest node 4.x' do
          let(:dependency_url) { 'https://example.com/node.4.6.0.txt' }

          it 'does not write to STDOUT' do
            expect(stdout).to eq ''
          end
        end

        context 'the version is not the latest node 4.x' do
          let(:dependency_url) { 'https://example.com/node.4.5.0.txt' }

          it 'write a warning telling the user to upgrade' do
            patch_warning = "**WARNING** A newer version of node is available in this buildpack. " +
              "Please adjust your app to use version 4.6.0 instead of version 4.5.0 as soon as possible. " +
              "Old versions of node are only provided to assist in migrating to newer versions."

            expect(stdout.chomp).to include patch_warning
          end
        end
      end
    end

    context 'the dependency is not found in the manifest' do
      let(:dependency_url) { 'https://example.com/another_thing.1.2.4.txt' }

      it 'does not write to STDOUT' do
        expect(stdout).to eq ''
      end
    end
  end

  describe 'dependencies are near EOL' do
    let(:dependency_eol) { '2016-02-30' }
    let(:eol_link) { 'https://github.com/nodejs/LTS-11' }

    let(:manifest_contents) do
      <<-MANIFEST
---
dependency_deprecation_dates:
  - match: 1.1.\\d
    version_line: 1.1
    name: dependency
    date: 2016-01-18
    link: https://github.com/nodejs/LTS-11
  - match: 1.2.\\d
    version_line: 1.2
    name: dependency
    date: #{dependency_eol}
    link: #{eol_link}

url_to_dependency_map:
  - match: .*dependency\.(.*)\.txt
    version: $1
    name: dependency

dependencies:
  - name: dependency
    version: 1.1.1
    uri: file://dependency.1.1.1.txt
    md5: 123456
    cf_stacks:
      - cflinuxfs2
  - name: dependency
    version: 1.2.3
    uri: file://dependency.1.2.3.txt
    md5: 123456
    cf_stacks:
      - cflinuxfs2
  - name: dependency
    version: 1.3.1
    uri: file://dependency.1.3.1.txt
    md5: 987654
    cf_stacks:
      - cflinuxfs2
      MANIFEST
    end

    context 'the dependency has a deprecation date' do
      let(:dependency_url) { 'https://example.com/dependency.1.2.3.txt' }
      context 'the date is more than 30 days away' do
        let(:dependency_eol) { (Date.today + 31).to_s }

        it 'does not write to STDOUT' do
          expect(stderr).to eq ''
        end
      end

      context 'the date is less than 30 days away' do
        let(:dependency_eol) { (Date.today + 29).to_s }

        it 'writes a warning telling the user to upgrade' do
          warning = "WARNING: dependency 1.2 will no longer be available in new buildpacks released after #{dependency_eol}." +
                    " See: #{eol_link}"
          expect(stderr).to include warning
        end
      end

      context 'the date is in the past' do
        let(:dependency_eol) { (Date.today - 10).to_s }

        it 'writes a warning telling the user to upgrade' do
          warning = "WARNING: dependency 1.2 will no longer be available in new buildpacks released after #{dependency_eol}." +
                    " See: #{eol_link}"

          expect(stderr).to include warning
        end
      end

      context 'the dependency deprecation information does not include a link' do
        let(:eol_link) { '' }
        let(:dependency_eol) { (Date.today - 10).to_s }

        it 'writes a warning telling the user to upgrade' do
          warning = "WARNING: dependency 1.2 will no longer be available in new buildpacks released after #{dependency_eol}."

          expect(stderr).to include warning
          expect(stderr).to_not include "See: "
        end
      end

      context 'the dependency does not have a deprecation date' do
        let(:dependency_url) { 'https://example.com/dependency.1.3.1.txt' }

        it 'does not write to STDOUT' do
          expect(stdout).to eq ''
        end
      end

      context 'different version line' do
        let(:dependency_url) { 'https://example.com/dependency.1.1.1.txt' }
        it 'writes a warning telling the user to upgrade' do
          warning = "WARNING: dependency 1.1 will no longer be available in new buildpacks released after 2016-01-18." +
            " See: #{eol_link}"

          expect(stderr).to include warning
        end
      end
    end
  end
end
