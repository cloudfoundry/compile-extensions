require 'yaml'
require 'uri'

module CompileExtensions
  module URITranslator

    def self.translate(uri)
      manifest = YAML.load_file(File.join(File.dirname(__FILE__), '..', '..', 'manifest.yml'))
      dependencies = CompileExtensions::Dependencies.new(manifest)

      translated_uri = dependencies.find_translated_url(uri)

      if translated_uri.nil?
        puts "DEPENDENCY_MISSING_IN_MANIFEST: #{filter_uri(uri)}"
        exit 1
      end

      cached_uri(translated_uri)
    end

    def self.cached_uri(uri)
      cache_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'dependencies'))
      return uri unless File.exist? cache_path

      filtered_uri = filter_uri(uri)
      file_path = File.join(cache_path, filtered_uri.gsub(/[\/:\?&]/, '_'))
      "file://#{file_path}"
    end

    def self.filter_uri(unsafe_uri)
      return "" if unsafe_uri.nil?
      uri_obj = URI(unsafe_uri)
      if uri_obj.userinfo
        uri_obj.user = "-redacted-" if uri_obj.user
        uri_obj.password = "-redacted-" if uri_obj.password
      end

      uri_obj.to_s
    end
  end
end
