require 'spec_helper'
require 'open3'

describe 'highest_version' do
  def run_highest_version(manifest_path, dependency, version)
    Open3.capture3("#{buildpack_directory}/compile-extensions/bin/highest_version #{manifest_path} #{dependency} #{version}")
  end

  let(:buildpack_directory) { Dir.mktmpdir }

  before do
    @base_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    `cp -a #{@base_dir} #{buildpack_directory}/compile-extensions`
  end

  context 'use semantically valid exact match' do
    let (:version) { '1.5.1' }
    let (:dependency) { 'go' }
    let(:manifest_path) { File.join(@base_dir, 'spec', 'fixtures', 'all_patch_level_manifest.yml') }

    it 'returns an exact match of the selected version' do
      highest_version, _, status = run_highest_version(manifest_path, dependency, version)
      expect(highest_version).to eq '1.5.1'
      expect(status).to eq(0)
    end
  end

  context 'use semantically valid version with no exact match' do
    let (:version) { '1.5.1' }
    let (:dependency) { 'go' }
    let(:manifest_path) { File.join(@base_dir, 'spec', 'fixtures', 'only_lts_manifest.yml') }

    it 'returns an exact match of the selected version' do
      highest_version, _, status = run_highest_version(manifest_path, dependency, version)
      expect(highest_version).to eq ''
      expect(status).to eq(0)
    end
  end

  context 'use wildcard without an exact major-minor match' do
    let (:version) { '1.5' }
    let (:dependency) { 'go' }
    let(:manifest_path) { File.join(@base_dir, 'spec', 'fixtures', 'all_patch_level_manifest.yml') }

    it 'returns an exact match of the selected version' do
      highest_version, _, status = run_highest_version(manifest_path, dependency, version)

      expect(highest_version).to eq '1.5.2'
      expect(status).to eq(0)
    end
  end

  context 'use wildcard with an exact major-minor match and no patch level' do

    let (:version) { '1.5' }
    let (:dependency) { 'go' }
    let(:manifest_path) { File.join(@base_dir, 'spec', 'fixtures', 'one_missing_patch_manifest.yml') }
    it 'returns highest minor version for specified major version' do
      highest_version, _, status = run_highest_version(manifest_path, dependency, version)
      expect(highest_version).to eq '1.5'
      expect(status).to eq(0)
    end
  end

  context 'use a wildcard match on an LTS version when a newer version is present' do
    let (:version) { '1.4' }
    let (:dependency) { 'go' }
    let(:manifest_path) { File.join(@base_dir, 'spec', 'fixtures', 'manifest.yml') }

    it 'returns an exact match of the selected version' do
      highest_version, _, status = run_highest_version(manifest_path, dependency, version)

      expect(highest_version).to eq '1.4.3'
      expect(status).to eq(0)
    end
  end

  context 'use a wildcard match when no major-minor matches present' do
    let (:version) { '1.5' }
    let (:dependency) { 'go' }
    let(:manifest_path) { File.join(@base_dir, 'spec', 'fixtures', 'only_lts_manifest.yml') }

    it 'returns an exact match of the selected version' do
      highest_version, _, status = run_highest_version(manifest_path, dependency, version)

      expect(highest_version).to eq ''
      expect(status).to eq(0)
    end
  end
end
