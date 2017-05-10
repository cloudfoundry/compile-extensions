require 'spec_helper'
require 'open3'

describe 'download_dependency_by_name' do
  def run_download_dependency_by_name(name, version, output_location)
    Open3.capture3("#{buildpack_directory}/compile-extensions/bin/download_dependency_by_name", name, version, output_location)
  end

  let(:credentials)          { 'login:password' }
  let(:redacted)             { '-redacted-:-redacted-' }
  let(:proxy)                { Billy::Proxy.new }
  let(:buildpack_directory)  { Dir.mktmpdir }
  let(:install_directory)    { Dir.mktmpdir }
  let(:dependency_file_name) { 'something.txt' }
  let!(:manifest) do
    File.open(File.join(buildpack_directory, 'manifest.yml'), 'w') do |file|
      file.write <<-MANIFEST
---
dependencies:
  - name: something
    version: 3
    uri: https://some_url.com/somthing3
    cf_stacks:
      - cflinuxfs2
    md5: 654321
  - name: something
    version: 0
    uri: #{manifest_url}
    cf_stacks:
      - cflinuxfs2
    md5: #{md5}
  - name: something
    version: 2
    uri: https://some_url.com/somthing2
    cf_stacks:
      - cflinuxfs2
    md5: 12345
      MANIFEST
    end
  end

  let(:file_path) do
    path = File.join(Dir.mktmpdir, dependency_file_name)
    File.write(path, 'something')
    path
  end
  let(:manifest_url) { "file://#{file_path}" }
  let(:md5)          { Digest::MD5.file(file_path).hexdigest }

  before do
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    `cp -a #{base_dir} #{buildpack_directory}/compile-extensions`
  end

  context 'cache path exists' do
    let(:url_body)             { "example.com/version-1.2.3/something.txt"}
    let(:manifest_url)         { "https://#{credentials}@#{url_body}" }
    let(:cached_file_location) { "#{buildpack_directory}/dependencies/https___-redacted-_-redacted-@#{url_body.gsub(/[\/:\?&]/, '_')}"}

    before do
      FileUtils.mkdir_p(File.join(buildpack_directory, 'dependencies'))
      File.write(cached_file_location, 'something')
    end

    it 'downloads a uri to a specified directory' do
      run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
      expect(File).to exist("#{install_directory}/something.txt")
    end

    it 'displays the translated uri to STDOUT' do
      stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
      expect(stdout.chomp).to include("file://#{cached_file_location}")
    end
  end

  context 'filename is in the manifest' do
    context 'When downloaded file has a valid checksum' do
      it 'downloads a uri to a specified directory' do
        run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
        expect(File).to exist("#{install_directory}/something.txt")
      end

      it 'displays the translated uri to STDOUT' do
        stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
        expect(stdout.chomp).to include(file_path)
      end

      context 'the uri contains credentials' do
        let(:manifest_url) { "file://#{credentials}@#{file_path}" }

        it 'does not write credentials to STDOUT' do
          stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
          expect(stdout.chomp).not_to include(credentials)
        end

        it 'redacts credentials from STDOUT' do
          stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
          expect(stdout.chomp).to include(redacted)
        end
      end
    end

    context 'When downloaded file has invalid checksum' do
      let(:md5) { Digest::MD5.hexdigest('something else') }

      it %Q{the process ends with failing exit code,
            and is '3' because of the PHP buildpack behaviour} do
        stdout, _, status = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
        generated_checksum = Digest::MD5.file(file_path).hexdigest
        expect(stdout.chomp).to match(/DEPENDENCY_MD5_MISMATCH for .*something\.txt: generated md5: #{Regexp.quote(generated_checksum)}, expected md5: #{Regexp.quote(md5)}/)
        expect(status.exitstatus).to eq 3
      end

      context 'the uri contains credentials' do
        let(:manifest_url) { "file://#{credentials}@#{file_path}" }

        it 'does not write credentials to STDOUT' do
          stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
          expect(stdout.chomp).not_to include(credentials)
        end

        it 'redacts credentials from STDOUT' do
          stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
          expect(stdout.chomp).to include(redacted)
        end
      end

      it 'File is not present at the specified directory' do
        run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
        expect(File).not_to exist("#{install_directory}/something.txt")
      end
    end
  end

  context 'dependency is not in the manifest' do
    it 'should display an error that the file is not in the manifest' do
      stdout, _, _ = run_download_dependency_by_name('something', '5', "#{install_directory}/something.txt")
      expect(stdout).to match 'DEPENDENCY_MISSING_IN_MANIFEST: something 5'
    end

    it 'has a specific exit code' do
      stdout, _, status = run_download_dependency_by_name('something', '5', "#{install_directory}/something.txt")
      expect(status.exitstatus).to eq 1
    end

    it 'does not download the file to the specified directory' do
      stdout, _, _ = run_download_dependency_by_name('something', '5', "#{install_directory}/something.txt")
      expect(File).not_to exist("#{install_directory}/something_else.txt")
    end
  end

  context 'download URI gives a redirect' do
    let(:manifest_url) { 'http://my.package.com/package.txt' }
    let(:md5)          { Digest::MD5.hexdigest 'blah blee' }

    before do
      proxy.start
      proxy.stub('http://my.package.com/package.txt').
        and_return(redirect_to: 'http://otherplace.com/thing.tgz')
      proxy.stub('http://otherplace.com/thing.tgz').
        and_return(text: "blah blee")
      ENV['http_proxy'] = proxy.url
    end

    after do
      proxy.reset
      ENV['http_proxy'] = nil
    end

    it 'follows the redirect' do
      stdout, _, _ = run_download_dependency_by_name('something', '0', "#{install_directory}/something.txt")
      expect(File).to exist("#{install_directory}/something.txt")
      expect(File.read("#{install_directory}/something.txt")).to eq 'blah blee'
    end
  end
end
