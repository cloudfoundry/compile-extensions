require 'spec_helper'
require 'yaml'
require 'fileutils'
require 'open3'

describe 'write config.yml' do
  def run_write_config_yml(buildpack_dir, dep_dir)
    Open3.capture3("./bin/write_config_yml #{buildpack_dir} #{dep_dir}")
  end

  let(:buildpack_dir) { Dir.mktmpdir }
  let(:dep_dir) { Dir.mktmpdir }

  before do
    manifest_contents = <<-MANIFEST
language: perl
dependencies: []
MANIFEST

    File.write(File.join(buildpack_dir, 'manifest.yml'), manifest_contents)
  end

  after do
    FileUtils.rm_rf(buildpack_dir)
    FileUtils.rm_rf(dep_dir)
  end

  it 'writes a config.yml file containing the buildpack name' do
    _, _, status = run_write_config_yml(buildpack_dir, dep_dir)
    expect(status.exitstatus).to eq 0

    expect(YAML.load_file(File.join(dep_dir, 'config.yml'))).to eq({ 'name' => 'perl', 'config' => {} })
  end
end
