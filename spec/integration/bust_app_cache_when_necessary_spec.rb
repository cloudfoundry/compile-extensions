require 'spec_helper'

describe 'the app cache dir' do

  def run_validate_app_cache
    Open3.capture3("#{buildpack_dir}/compile-extensions/bin/validate_app_cache #{app_cache_dir}")
  end

  def run_store_stack_value
    Open3.capture3("#{buildpack_dir}/compile-extensions/bin/store_stack_value #{app_cache_dir}")
  end

  let(:buildpack_dir) { Dir.mktmpdir }
  let(:app_cache_dir) { Dir.mktmpdir }

  before do
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    `cd #{buildpack_dir} && cp -r #{base_dir} compile-extensions`
  end

  after do
    FileUtils.remove_entry(app_cache_dir) if Dir.exist?(app_cache_dir)
    FileUtils.remove_entry(buildpack_dir) if Dir.exist?(buildpack_dir)

    ENV['CF_STACK'] = nil
  end

  context 'when the stack has changed' do

    it 'should be busted' do
      ENV['CF_STACK'] = 'lucid64'
      run_store_stack_value
      ENV['CF_STACK'] = 'cflinuxfs2'
      run_validate_app_cache

      expect(Dir).not_to exist(app_cache_dir)
    end
  end

  context 'when the stack remains the same' do
    
    it 'should NOT be busted' do
      ENV['CF_STACK'] = 'lucid64'
      run_store_stack_value
      run_validate_app_cache

      expect(Dir).to exist(app_cache_dir)
    end
  end

  context 'when the stack is not specified in the cache' do
    
    it 'should be busted' do
      ENV['CF_STACK'] = 'cflinuxfs2'
      run_validate_app_cache

      expect(Dir).not_to exist(app_cache_dir)
    end
  end

  context 'when the CF_STACK variable is not set in the environment' do
    
    it 'should be busted' do
      ENV['CF_STACK'] = 'lucid64'
      run_store_stack_value
      ENV['CF_STACK'] = nil
      run_validate_app_cache

      expect(Dir).not_to exist(app_cache_dir)
    end
  end
end
