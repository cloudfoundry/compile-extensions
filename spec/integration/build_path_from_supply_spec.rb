require 'spec_helper'
require 'fileutils'
require 'open3'

describe 'build path from supply' do
  def run_build_path_from_supply(deps_dir)
    Open3.capture3("./bin/build_path_from_supply #{deps_dir}")
  end

  context 'deps dir exists' do
    let(:deps_dir) { Dir.mktmpdir }

    context 'both exes and libs are provided' do
      before do
        FileUtils.mkdir_p("#{deps_dir}/00/bin")
        FileUtils.mkdir_p("#{deps_dir}/01/bin")
        FileUtils.mkdir_p("#{deps_dir}/01/lib")
        FileUtils.mkdir_p("#{deps_dir}/02/lib")
      end

      after do
        FileUtils.rm_rf(deps_dir)
      end

      it 'writes the updated environment variables to STDOUT' do
        stdout, _, status = run_build_path_from_supply(deps_dir)
        expect(status.exitstatus).to eq 0

        path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin:#{ENV['PATH']}"
        ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/lib:#{deps_dir}/01/lib:#{ENV['LD_LIBRARY_PATH']}"


        expect(stdout.split("\n")[0]).to eq path
        expect(stdout.split("\n")[1]).to eq ld_library_path
      end
    end

    context 'just exes are provided' do
      before do
        FileUtils.mkdir_p("#{deps_dir}/00/bin")
        FileUtils.mkdir_p("#{deps_dir}/01/bin")
      end

      after do
        FileUtils.rm_rf(deps_dir)
      end

      it 'only PATH is written to stdout' do
        stdout, _, status = run_build_path_from_supply(deps_dir)
        expect(status.exitstatus).to eq 0

        path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin:#{ENV['PATH']}"

        expect(stdout.split("\n")[0]).to eq path
        expect(stdout.split("\n")[1]).to eq nil
      end

    end

    context 'just libs are provided' do
      before do
        FileUtils.mkdir_p("#{deps_dir}/01/lib")
        FileUtils.mkdir_p("#{deps_dir}/02/lib")
      end

      after do
        FileUtils.rm_rf(deps_dir)
      end

      it 'only LD_LIBRARY_PATH is written to stdout' do
        stdout, _, status = run_build_path_from_supply(deps_dir)
        expect(status.exitstatus).to eq 0

        ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/lib:#{deps_dir}/01/lib:#{ENV['LD_LIBRARY_PATH']}"

        expect(stdout.split("\n")[0]).to eq ld_library_path
        expect(stdout.split("\n")[1]).to eq nil
      end
    end
  end

  context 'deps dir does not exist' do
    it 'writes nothing' do
      stdout, _, status = run_build_path_from_supply('not exist')
      expect(status.exitstatus).to eq 0

      expect(stdout).to eq ""
    end
  end
end
