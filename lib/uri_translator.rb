require 'yaml'
require 'uri'

module CompileExtensions
  module URITranslator
    def self.translate(uri, filter_credentials = false)
      cache_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'dependencies'))

      manifest = YAML.load_file(File.join(File.dirname(__FILE__), '..', '..', 'manifest.yml'))
      dependencies = CompileExtensions::Dependencies.new(manifest)

      translated_uri = dependencies.find_translated_url(uri)

      if translated_uri.nil?
        exit 1
      end

      if filter_credentials
        translated_uri=filter_uri(translated_uri)
      end

      if File.exist? cache_path
        file_path = File.join(cache_path, translated_uri.gsub(/[\/:\?&]/, '_'))
        translated_uri = "file://#{file_path}"
      end

      if ENV['BP_DEBUG']
        STDERR.puts "DEBUG: #{File.basename(__FILE__)}: #{translated_uri}"
      end

      translated_uri
    end

    def self.filter_uri(unsafe_uri)
      return "" if unsafe_uri.nil?

      uri_obj = URI(unsafe_uri)
      if uri_obj.userinfo
        uri_obj.user = "-redacted-" if uri_obj.user
        uri_obj.password = "-redacted-" if uri_obj.password
        safe_uri = uri_obj.to_s
      else
        safe_uri = uri_obj.to_s
      end

      safe_uri
    end
  end
end
