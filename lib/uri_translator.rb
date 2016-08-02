require 'yaml'
require 'uri'

module CompileExtensions
  module URITranslator
    def self.translate(uri)
      cache_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'dependencies'))

      manifest = YAML.load_file(File.join(File.dirname(__FILE__), '..', '..', 'manifest.yml'))
      dependencies = CompileExtensions::Dependencies.new(manifest)

      translated_uri = dependencies.find_translated_url(uri)

      if translated_uri.nil?
        exit 1
      end

      if File.exist? cache_path
        filtered_uri = filter_uri(translated_uri)
        file_path = File.join(cache_path, filtered_uri.gsub(/[\/:\?&]/, '_'))
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
      end

      if uri_obj.scheme == 'file'
        safe_uri = repair_file_uri(uri_obj)
      else
        safe_uri = uri_obj.to_s
      end

      safe_uri
    end

    def self.repair_file_uri(uri_obj)
      ## URI("file:///directory/thing.tgz").to_s -> "file:/directory/thing.tgz"
      uri_obj.to_s.sub("file:", "file://")
    end
  end
end
