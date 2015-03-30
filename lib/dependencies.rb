module CompileExtensions
  class Dependencies
    def initialize(manifest)
      @manifest = manifest
    end

    def find_matching_dependency(uri)
      mapping = find_dependency_mapping(uri)

      return nil if mapping.nil?

      mapping = transform_mapping_values(mapping, uri)
      find_dependency_with_mapping(mapping)
    end

    def find_translated_url(uri)
      dependency = find_matching_dependency(uri)

      return nil if dependency.nil?

      dependency['uri']
    end

    def find_md5(uri)
      dependency = find_matching_dependency(uri)

      return nil if dependency.nil?

      dependency['md5']
    end

    private

    def transform_mapping_values(mapping, uri)
      matches = uri.match(mapping['match'])
      %w{name version}.each do |key|
        if matches.length > 1
          (1...matches.length).each do |index|
            mapping[key].gsub!("$#{index}", matches[index])

          end
        end
      end
      mapping
    end

    def find_dependency_mapping(uri)
      @manifest['url_to_dependency_map'].find do |mapping|
        uri.match(mapping['match'])
      end

    end

    def find_dependency_with_mapping(mapping)
      @manifest['dependencies'].find do |dependency|
        dependency['version'].to_s == mapping['version'].to_s &&
          dependency['name'] == mapping['name'] &&
          dependency_satisfies_current_stack(dependency)
      end
    end

    def dependency_satisfies_current_stack(dependency)
      dependency['cf_stacks'].include?(stack)
    end

    def stack
      ENV['CF_STACK'] || 'lucid64'
    end
  end
end
