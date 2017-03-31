require_relative "#{File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'env_builder')}"
require 'tmpdir'
require 'fileutils'

describe EnvBuilder do
  let(:deps_dir)    { Dir.mktmpdir }
  let(:deps_prefix) { 'arbitrary_string' }


  subject {described_class.new(deps_dir, deps_prefix)}

  before do
    FileUtils.mkdir_p("#{deps_dir}/00/bin")
    FileUtils.mkdir_p("#{deps_dir}/01/bin")
    FileUtils.mkdir_p("#{deps_dir}/01/lib")
    FileUtils.mkdir_p("#{deps_dir}/02/lib")
  end

  after do
    FileUtils.rm_rf(deps_dir)
  end

  describe '#path' do
    it 'returns the directories to be prepended to PATH' do
      path = "arbitrary_string/01/bin:arbitrary_string/00/bin"
      expect(subject.path).to eq path
    end
  end

  describe '#ld_library_path' do
    it 'returns the directories to be prepended to LD_LIBRARY_PATH' do
      ld_library_path = "arbitrary_string/02/lib:arbitrary_string/01/lib"
      expect(subject.ld_library_path).to eq ld_library_path
    end
  end
end
