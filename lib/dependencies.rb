module CompileExtensions
  class Dependencies
    def initialize(manifest)
      @manifest = manifest
    end

    def find_matching_dependency(uri)
      @manifest['dependencies'].find do |dependency|
        dependency['original'] == uri
      end
    end

    def find_translated_dependency(uri)
      dependency = find_matching_dependency(uri)

      return nil if dependency.nil?

      dependency['xlated']
    end
  end
end
