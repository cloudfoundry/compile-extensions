require 'spec_helper'
require 'open3'
require 'yaml'

describe 'store_buildpack_metadata' do
  def store_buildpack_metadata(buildpack_directory, cache_dir)
    Open3.capture3("#{buildpack_directory}/compile-extensions/bin/store_buildpack_metadata #{buildpack_directory} #{cache_dir}")
  end

  let(:buildpack_directory)         { Dir.mktmpdir }
  let(:staging_buildpack_version)       { '4.0.1' }
  let(:staging_language)                { 'go' }
  let(:manifest_contents) {
    <<-MANIFEST
    language: #{staging_language}
    MANIFEST
  }

  let(:cache_dir)                   { Dir.mktmpdir }
  let(:staged_buildpack_version)       { '4.0.0' }
  let(:staged_buildpack_metadata_file) { File.join(cache_dir, 'BUILDPACK_METADATA') }
  let(:staged_language)                { 'go' }
  let(:staged_buildpack_metadata) {
    <<-METADATA
    language: #{staged_language}
    version: #{staged_buildpack_version}
    METADATA
  }

  before do
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    `cp -a #{base_dir} #{buildpack_directory}/compile-extensions`
  end

  context 'the current buildpack that is staging has a manifest.yml file' do
    before do
      File.open(File.join(buildpack_directory, 'manifest.yml'), 'w') do |file|
        file.write(manifest_contents)
      end
    end

    context 'the current buildpack that is staging has a VERSION file' do
      before { File.write(File.join(buildpack_directory, 'VERSION'), staging_buildpack_version) }

      context 'BUILDPACK_METADATA file already exists in the cache dir' do
        before do
          File.write(staged_buildpack_metadata_file, staged_buildpack_metadata)
        end

        it 'writes the buildpack metadata to the BUILDPACK_METADATA file in the cache dir' do
          stdout, stderr, status = store_buildpack_metadata(buildpack_directory, cache_dir)

          expect(status.exitstatus).to eq 0

          staged_buildpack_metadata = YAML.load_file(staged_buildpack_metadata_file)
          expect(staged_buildpack_metadata['language']).to eq('go')
          expect(staged_buildpack_metadata['version']).to eq('4.0.1')
        end
      end

      context 'BUILDPACK_METADATA file does not already exist in the cache dir' do
        it 'creates the BUILDPACK_METADATA file in the cache dir and writes the buildpack metadata to it' do
          stdout, stderr, status = store_buildpack_metadata(buildpack_directory, cache_dir)

          expect(status.exitstatus).to eq 0

          staged_buildpack_metadata = YAML.load_file(staged_buildpack_metadata_file)
          expect(staged_buildpack_metadata['language']).to eq('go')
          expect(staged_buildpack_metadata['version']).to eq('4.0.1')
        end
      end

      context 'cache dir does not exist' do
        let(:cache_dir) { 'not/a/real/directory/' }

        it 'exits without an exception' do
          stdout, stderr, status = store_buildpack_metadata(buildpack_directory, cache_dir)

          expect(status.exitstatus).to eq 0

          expect(stdout).to eq('')
          expect(stderr).to eq('')
        end
      end

      context 'the current buildpack that is staging has a blank VERSION file' do
        before { File.write(File.join(buildpack_directory, 'VERSION'), "") }

        it 'does nothing' do
          stdout, stderr, status = store_buildpack_metadata(buildpack_directory, cache_dir)

          expect(status.exitstatus).to eq 0
          expect(stderr).to be_empty
        end
      end
    end

    context 'the current buildpack that is staging does not have a VERSION file' do
      it 'does nothing' do
        stdout, stderr, status = store_buildpack_metadata(buildpack_directory, cache_dir)

        expect(status.exitstatus).to eq 0
        expect(stderr).to be_empty
      end
    end
  end

  context 'the current buildpack that is staging is missing a manifest.yml file' do
    it 'does nothing' do
      stdout, stderr, status = store_buildpack_metadata(buildpack_directory, cache_dir)

      expect(status.exitstatus).to eq 0
      expect(stderr).to be_empty
    end
  end
end
