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

        if ENV['PATH'].to_s.length > 0
          path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin:#{ENV['PATH']}"
        else
          path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin"
        end

        if ENV['LD_LIBRARY_PATH'].to_s.length > 0
          ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/lib:#{deps_dir}/01/lib:#{ENV['LD_LIBRARY_PATH']}"
        else
          ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/lib:#{deps_dir}/01/lib"
        end

        expect(stdout.split("\n")).to eq [path, ld_library_path]
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

        if ENV['PATH'].to_s.length > 0
          path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin:#{ENV['PATH']}"
        else
          path = "PATH=#{deps_dir}/01/bin:#{deps_dir}/00/bin"
        end

        expect(stdout.split("\n")).to eq [path]
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

        if ENV['LD_LIBRARY_PATH'].to_s.length > 0
          ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/lib:#{deps_dir}/01/lib:#{ENV['LD_LIBRARY_PATH']}"
        else
          ld_library_path = "LD_LIBRARY_PATH=#{deps_dir}/02/lib:#{deps_dir}/01/lib"
        end

        expect(stdout.split("\n")).to eq [ld_library_path]
      end
    end

    context 'include paths are provided' do
      before do
        FileUtils.mkdir_p("#{deps_dir}/01/include")
        FileUtils.mkdir_p("#{deps_dir}/07/include")
        FileUtils.mkdir_p("#{deps_dir}/04/include")
      end

      after do
        FileUtils.rm_rf(deps_dir)
      end

      it 'INCLUDE_PATH, CPATH and CPPPATH are written to stdout' do
        stdout, _, status = run_build_path_from_supply(deps_dir)
        expect(status.exitstatus).to eq 0

        if ENV['INCLUDE_PATH'].to_s.length > 0
          include_path = "INCLUDE_PATH=#{deps_dir}/07/include:#{deps_dir}/04/include:#{deps_dir}/01/include:#{ENV['INCLUDE_PATH']}"
        else
          include_path = "INCLUDE_PATH=#{deps_dir}/07/include:#{deps_dir}/04/include:#{deps_dir}/01/include"
        end

        if ENV['CPATH'].to_s.length > 0
          cpath = "CPATH=#{deps_dir}/07/include:#{deps_dir}/04/include:#{deps_dir}/01/include:#{ENV['CPATH']}"
        else
          cpath = "CPATH=#{deps_dir}/07/include:#{deps_dir}/04/include:#{deps_dir}/01/include"
        end

        if ENV['CPPPATH'].to_s.length > 0
          cpppath= "CPPPATH=#{deps_dir}/07/include:#{deps_dir}/04/include:#{deps_dir}/01/include:#{ENV['CPPPATH']}"
        else
          cpppath= "CPPPATH=#{deps_dir}/07/include:#{deps_dir}/04/include:#{deps_dir}/01/include"
        end

        expect(stdout.split("\n")).to eq [include_path, cpath, cpppath]
      end
    end

    context 'pkgconfig paths are provided' do
      before do
        FileUtils.mkdir_p("#{deps_dir}/02/pkgconfig")
        FileUtils.mkdir_p("#{deps_dir}/08/pkgconfig")
        FileUtils.mkdir_p("#{deps_dir}/05/pkgconfig")
      end

      after do
        FileUtils.rm_rf(deps_dir)
      end

      it 'PKG_CONFIG_PATH is written to stdout' do
        stdout, _, status = run_build_path_from_supply(deps_dir)
        expect(status.exitstatus).to eq 0

        if ENV['PKG_CONFIG_PATH'].to_s.length > 0
          pkgconfig_path = "PKG_CONFIG_PATH=#{deps_dir}/08/pkgconfig:#{deps_dir}/05/pkgconfig:#{deps_dir}/02/pkgconfig:#{ENV['PKG_CONFIG_PATH']}"
        else
          pkgconfig_path = "PKG_CONFIG_PATH=#{deps_dir}/08/pkgconfig:#{deps_dir}/05/pkgconfig:#{deps_dir}/02/pkgconfig"
        end

        expect(stdout.split("\n")).to eq [pkgconfig_path]
      end
    end

    context 'env is provided' do
      before do
        FileUtils.mkdir_p("#{deps_dir}/01/env")
        FileUtils.mkdir_p("#{deps_dir}/02/env")
        File.write("#{deps_dir}/02/env/ENV_ONE", "xxx")
        FileUtils.mkdir_p("#{deps_dir}/03/env")
        File.write("#{deps_dir}/03/env/ENV_TWO", "yyy")
      end

      it 'outputs env to stdout' do
        stdout, _, status = run_build_path_from_supply(deps_dir)

        expect(status.exitstatus).to eq 0
        expect(stdout.split("\n")).to eq %w(ENV_ONE=xxx ENV_TWO=yyy)
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
