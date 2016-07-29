require 'spec_helper'

describe 'filtered_dependency_url' do
  def run_filter
    Open3.capture3("#{compile_extensions_dir}/bin/filter_dependency_url #{original_url}")
  end

  let(:compile_extensions_dir) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..")) }

  context 'with credentials in the url' do
    let(:credentials) { 'login:password' }
    let(:redacted) { '-redacted-:-redacted-' }

    context 'python 2.7.11' do
      let(:original_url) { "https://#{credentials}@python.com/2.7.11.tgz" }

      it 'redacts the credentials' do
        filtered_url, _, _ = run_filter
        expect(filtered_url).to eq "https://#{redacted}@python.com/2.7.11.tgz\n"
      end
    end

    context 'the uri is a file' do
      let(:original_url) { "file://#{credentials}@/file/path/would/go/here.txt" }

      it 'redacts the credentials' do
        filtered_url, _, _ = run_filter

        expect(filtered_url).to eq("file://#{redacted}@/file/path/would/go/here.txt\n")
      end
    end

    context 'the uri has parameters' do
      let(:original_url) { "https://#{credentials}@some.cdn/with?parameters=true\\&secondParameter=present" }

      it 'redacts the credentials' do
        filtered_url, _, _ = run_filter

        expect(filtered_url).to eq("https://#{redacted}@some.cdn/with?parameters=true&secondParameter=present\n")
      end
    end
  end

  context 'with no credentials in the url' do
    context 'ruby 2.3.1' do
      let(:original_url) { 'https://original.com/ruby-2.3.1.tgz' }

      it 'returns the same url' do
        filtered_url, _, _ = run_filter

        expect(filtered_url).to eq "https://original.com/ruby-2.3.1.tgz\n"
      end
    end

    context 'the uri is a file' do
      let(:original_url) { "file:///file/path/would/go/here.txt" }

      it 'returns the same url' do
        filtered_url, _, _ = run_filter

        expect(filtered_url).to eq "file:///file/path/would/go/here.txt\n"
      end
    end

    context 'the uri is not a uri but a path' do
      let(:original_url) { "/file/path/would/go/here.txt" }

      it 'returns the same url' do
        filtered_url, _, _ = run_filter

        expect(filtered_url).to eq "/file/path/would/go/here.txt\n"
      end
    end

    context 'parameters in the url' do
      let(:original_url) { 'https://some.cdn/with?parameters=true\&secondParameter=present' }

      it 'returns the same url' do
        filtered_url, _, _ = run_filter

        expect(filtered_url).to eq "https://some.cdn/with?parameters=true&secondParameter=present\n"
      end
    end
  end
end
