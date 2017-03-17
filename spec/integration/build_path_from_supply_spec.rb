require 'spec_helper'
require 'fileutils'
require 'open3'

describe 'build path from supply' do
  def run_build_path_from_supply(deps_dir)
    Open3.capture3("./bin/build_path_from_supply #{deps_dir}")
  end

  context 'deps dir exists' do
    let(:deps_dir) { Dir.mktmpdir }

    before do
      FileUtils.mkdir_p("#{deps_dir}/00/bin")
      FileUtils.mkdir_p("#{deps_dir}/01/bin")
      FileUtils.mkdir_p("#{deps_dir}/01/ld_library_path")
      FileUtils.mkdir_p("#{deps_dir}/02/ld_library_path")
    end

    after do
      FileUtils.rm_rf(deps_dir)
    end

    it 'writes the updated environment variables to STDOUT' do
      stdout, _, status = run_build_path_from_supply(deps_dir)
      expect(status.exitstatus).to eq 0

      path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin:#{ENV['PATH']}"
      ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/ld_library_path:#{deps_dir}/01/ld_library_path:#{ENV['LD_LIBRARY_PATH']}"


      expect(stdout.split("\n")[0]).to eq path
      expect(stdout.split("\n")[1]).to eq ld_library_path
    end
  end

  context 'deps dir does not exist' do
    it 'writes the existing environment variables to STDOUT' do
      stdout, _, status = run_build_path_from_supply('not exist')
      expect(status.exitstatus).to eq 0

      expect(stdout.split("\n")[0]).to eq "PATH=#{ENV['PATH']}"
      expect(stdout.split("\n")[1]).to eq "LD_LIBRARY_PATH=#{ENV['LD_LIBRARY_PATH']}"
    end
  end
end
