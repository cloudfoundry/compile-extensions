require 'spec_helper'
require 'fileutils'
require 'open3'

describe 'write .profile.d from supply' do
  def run_write_profiled_from_supply(deps_dir, build_dir)
    Open3.capture3("./bin/write_profiled_from_supply #{deps_dir} #{build_dir}")
  end

  let(:build_dir) { Dir.mktmpdir }
  let(:profiled_script) {File.join(build_dir, ".profile.d", "00-multi-supply.sh")}

  context 'deps dir exists' do
    let(:deps_dir)  { Dir.mktmpdir }

    before do
      FileUtils.mkdir_p("#{deps_dir}/00/bin")
      FileUtils.mkdir_p("#{deps_dir}/01/bin")
      FileUtils.mkdir_p("#{deps_dir}/01/ld_library_path")
      FileUtils.mkdir_p("#{deps_dir}/02/ld_library_path")
    end

    after do
      FileUtils.rm_rf(deps_dir)
    end

    it 'writes appropriate export commands to .profile.d/00-multi-supply.sh script' do
      _, _, status = run_write_profiled_from_supply(deps_dir, build_dir)
      expect(status.exitstatus).to eq 0

      path_export = 'export PATH="$DEPS_DIR/01/bin:$DEPS_DIR/00/bin:$PATH"'
      ld_library_path_export = 'export LD_LIBRARY_PATH="$DEPS_DIR/02/ld_library_path:$DEPS_DIR/01/ld_library_path:$LD_LIBRARY_PATH"'

      content = File.read(profiled_script)
      expect(content).to include path_export
      expect(content).to include ld_library_path_export
    end
  end

  context 'deps dir does not exist' do
    it 'does not write anything' do
      _, _, status = run_write_profiled_from_supply("not exist", build_dir)
      expect(status.exitstatus).to eq 0
      expect(File.exist?(profiled_script)).to be false
    end
  end
end


