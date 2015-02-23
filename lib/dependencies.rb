module CompileExtensions
  class Dependencies
    ALL_STACKS_IDENTIFIER = "all"

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
        dependency['version'] == mapping['version'] &&
          dependency['name'] == mapping['name'] &&
          dependency_satisfies_current_stack(dependency)
      end
    end

    def dependency_satisfies_current_stack(dependency)
      return true if dependency['cf_stacks'] == ALL_STACKS_IDENTIFIER

      dependency['cf_stacks'].include?(ENV['CF_STACK'])
    end
  end
end
