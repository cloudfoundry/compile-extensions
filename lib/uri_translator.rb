require 'yaml'

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
        file_path = File.join(cache_path, translated_uri.gsub(/[\/:\?&]/, '_'))
        translated_uri = "file://#{file_path}"
      end

      if ENV['BP_DEBUG']
        STDERR.puts "DEBUG: #{File.basename(__FILE__)}: #{translated_uri}"
      end
      translated_uri
    end
  end
end
