require 'spec_helper'
require 'open3'
require 'fileutils'

describe 'check_buildpack_version' do
  def check_buildpack_version(buildpack_directory, cache_dir)
    Open3.capture3("#{buildpack_directory}/compile-extensions/bin/check_buildpack_version #{buildpack_directory} #{cache_dir}")
  end

  let(:buildpack_directory)             { Dir.mktmpdir }
  let(:cache_dir)                       { Dir.mktmpdir }

  before do
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    `cp -a #{base_dir} #{buildpack_directory}/compile-extensions`
  end

  after do
    FileUtils.rm_r(buildpack_directory)
    FileUtils.rm_r(cache_dir)
  end

  context 'the manifest.yml does not exist for the staging buildpack' do
    let(:staging_buildpack_version_file) {File.join(buildpack_directory, 'VERSION')}
    let(:buildpack_metadata_file) {File.join(cache_dir, 'BUILDPACK_METADATA')}

    before do
      File.write(staging_buildpack_version_file, 'override')
      File.write(buildpack_metadata_file, 'override')
    end

    it 'does not display a warning' do
      stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

      expect(status.exitstatus).to eq 0
      expect(stdout).to be_empty
    end
  end

  context 'the manifest.yml exists for the staging buildpack' do
    let(:staging_buildpack_manifest_file) { File.join(buildpack_directory, 'manifest.yml') }
    before { File.write(staging_buildpack_manifest_file, 'override') }

    context 'the VERSION file does not exist for the staging buildpack' do
      let(:buildpack_metadata_file)       {File.join(cache_dir, 'BUILDPACK_METADATA')}

      before do
        File.write(buildpack_metadata_file, 'override')
      end

      it 'does not display a warning' do
        stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

        expect(status.exitstatus).to eq 0
        expect(stdout).to be_empty
      end
    end

    context 'the VERSION file exists for the staging buildpack' do
      let(:staging_buildpack_version_file)  { File.join(buildpack_directory, 'VERSION') }
      before { File.write(staging_buildpack_version_file, 'override') }

      context 'the staged buildpack metadata file does not exist in the cache dir' do
        it 'does not display a warning' do
          stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

          expect(status.exitstatus).to eq 0
          expect(stdout).to be_empty
        end
      end

      context 'the staged buildpack metadata file exists in the cache dir' do
        let(:buildpack_metadata_file)         { File.join(cache_dir, 'BUILDPACK_METADATA') }

        before do
          staged_buildpack_metadata = <<-METADATA
          language: ruby
          version: 4.0.0
          METADATA
          File.write(buildpack_metadata_file, staged_buildpack_metadata)
        end

        context 'the staged buildpack language is the same as the staging buildpack language' do
          let(:staging_buildpack_manifest) {
            <<-MANIFEST
            language: ruby
            MANIFEST
          }

          before do
            File.write(staging_buildpack_manifest_file, staging_buildpack_manifest)
          end

          context 'the staged buildpack version is the same as the staging buildpack version' do
            before do
              File.write(staging_buildpack_version_file, '4.0.0')
            end

            it 'does not display a warning' do
              stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

              expect(status.exitstatus).to eq 0
              expect(stdout).to be_empty
            end
          end

          context 'the staged buildpack version is different as the staging buildpack version' do
            before { File.write(staging_buildpack_version_file, '4.0.1') }

            it 'displays a useful warning' do
              stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

              expect(status.exitstatus).to eq 0
              expect(stdout).to include("WARNING: buildpack version changed from 4.0.0 to 4.0.1")
            end
          end
        end

        context 'the staged buildpack language is not the same as the staging buildpack language' do
          let(:staging_buildpack_manifest) {
            <<-MANIFEST
            language: not-ruby
            MANIFEST
          }

          before do
            File.write(staging_buildpack_manifest_file, staging_buildpack_manifest)
          end

          it 'does not display a warning' do
            stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

            expect(status.exitstatus).to eq 0
            expect(stdout).to be_empty
          end
        end
      end

      context 'a malformed staged buildpack metadata file exists in the cache dir' do
        let(:buildpack_metadata_file)         { File.join(cache_dir, 'BUILDPACK_METADATA') }
        let(:staging_buildpack_manifest) {
            <<-MANIFEST
            language: ruby
            MANIFEST
        }
        let(:staging_buildpack_metadata) {
          <<-METADATA
          ---
          []
          METADATA
        }

        before do
          File.write(buildpack_metadata_file, staging_buildpack_metadata)
          File.write(staging_buildpack_manifest_file, staging_buildpack_manifest)
        end

        it 'exits without an exception' do
          stdout, stderr, status = check_buildpack_version(buildpack_directory, cache_dir)

          expect(status.exitstatus).to eq 0
          expect(stdout).to be_empty
          expect(stderr).to be_empty
        end
      end
    end
  end
end
