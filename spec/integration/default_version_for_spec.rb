require 'spec_helper'
require 'open3'

describe 'default_version_for' do
  def default_version_for(buildpack_directory, manifest_path, dependency_name)
    Open3.capture3("#{buildpack_directory}/compile-extensions/bin/default_version_for #{manifest_path} #{dependency_name}")
  end

  let(:buildpack_directory)    { Dir.mktmpdir }
  let(:dependency_name)        { 'Testlang' }
  let(:manifest_path)          { File.join(buildpack_directory, 'manifest.yml') }
  let(:defaults_error_message) { "The buildpack manifest is misconfigured for 'default_versions'. " +
                                  'Contact your Cloud Foundry operator/admin. For more information, ' +
                                  'see https://docs.cloudfoundry.org/buildpacks/custom.html#specifying-default-versions' }

  before do
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    `cp -a #{base_dir} #{buildpack_directory}/compile-extensions`
    File.open(manifest_path, 'w') do |file|
      file.write(manifest_contents)
    end
  end

  shared_examples_for 'erroring with helpful defaults misconfiguration message' do
    it 'errors out with a helpful buildpack manifest defaults is misconfigured message' do
      _, error_message, status = default_version_for(buildpack_directory, manifest_path, dependency_name)
      expect(status.exitstatus).to eq 1
      expect(error_message).to include defaults_error_message
    end
  end

  context 'manifest with correct default for the requested dependency' do
    let(:manifest_contents) { <<-MANIFEST
---
default_versions:
  - name: Testlang
    version: 11.0.1
  - name: SomethingElse
    version: 0.0.1

dependencies:
  - name: Testlang
    version: 1.0.1
  - name: Testlang
    version: 5.0.1
  - name: Testlang
    version: 11.0.1
      MANIFEST
    }

    it 'returns the default version set in the manifest for the dependency' do
      default_version, _, status = default_version_for(buildpack_directory, manifest_path, dependency_name)
      expect(status.exitstatus).to eq 0
      expect(default_version).to eq '11.0.1'
    end

    context "when BP_DEBUG is set" do
      before { ENV['BP_DEBUG'] = 'true' }

      after { ENV['BP_DEBUG'] = nil }

      it 'logs the default version identified for the dependency to STDERR' do
        _, stderr_output, status = default_version_for(buildpack_directory, manifest_path, dependency_name)
        expect(status.exitstatus).to eq 0
        expect(stderr_output).to include 'DEBUG: default_version_for Testlang is 11.0.1'
      end
    end
  end

  context 'manifest with multiple defaults for the requested dependency' do
    let(:manifest_contents) { <<-MANIFEST
---
default_versions:
  - name: Testlang
    version: 11.0.1
  - name: Testlang
    version: 11.0.2
  - name: SomethingElse
    version: 0.0.1

dependencies:
  - name: Testlang
    version: 1.0.1
  - name: Testlang
    version: 5.0.1
  - name: Testlang
    version: 11.0.1
      MANIFEST
    }

    it_behaves_like 'erroring with helpful defaults misconfiguration message'
  end

  context 'manifest with a default that has no matching dependency' do
    context 'where the name is missing' do
      let(:manifest_contents) { <<-MANIFEST
---
default_versions:
  - name: Testlang
    version: 11.0.1
  - name: SomethingElse
    version: 0.0.1

dependencies:
  - name: SomethingElse
    version: 0.0.1
      MANIFEST
      }

      it_behaves_like 'erroring with helpful defaults misconfiguration message'
    end

    context "where the version is missing" do
      let(:manifest_contents) { <<-MANIFEST
---
default_versions:
  - name: Testlang
    version: 11.0.1
  - name: SomethingElse
    version: 0.0.1

dependencies:
  - name: Testlang
    version: 11.0.2
  - name: SomethingElse
    version: 0.0.1
      MANIFEST
      }

      it_behaves_like 'erroring with helpful defaults misconfiguration message'
    end
  end

  context 'manifest with no default for the requested dependency' do
    let(:manifest_contents) { <<-MANIFEST
---
default_versions:
  - name: SomethingElse
    version: 0.0.1

dependencies:
  - name: Testlang
    version: 11.0.2
  - name: SomethingElse
    version: 0.0.1
      MANIFEST
    }

    it_behaves_like 'erroring with helpful defaults misconfiguration message'
  end

  context "manifest with no 'default_versions' section" do
    let(:manifest_contents) { <<-MANIFEST
dependencies:
  - name: Testlang
    version: 11.0.2
MANIFEST
    }

    it_behaves_like 'erroring with helpful defaults misconfiguration message'
  end

  context "one argument is provided" do
    let(:manifest_contents) { 'does not matter' }

    it 'errors with a helpful message' do
      _, error_message, status = default_version_for(buildpack_directory, 'manifest.yml', '')
      expect(status.exitstatus).to eq 1
      expect(error_message).to include 'Must provide both a buildpack manifest and dependency'
    end
  end

  context "no arguments are provided" do
    let(:manifest_contents) { 'does not matter' }

    it 'errors with a helpful message' do
      _, error_message, status = default_version_for(buildpack_directory, '', '')
      expect(status.exitstatus).to eq 1
      expect(error_message).to include 'Must provide both a buildpack manifest and dependency'
    end
  end
end
