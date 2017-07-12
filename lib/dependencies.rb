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

    def find_dependency(uri)
      mapping = find_dependency_mapping(uri)

      return nil if mapping.nil?

     transform_mapping_values(mapping, uri)
    end

    def find_dependency_by_name(name, version)
      @manifest['dependencies'].find do |dependency|
        dependency['version'].to_s == version.to_s &&
          dependency['name'] == name &&
          dependency_satisfies_current_stack(dependency)
      end
    end

    def valid_versions(hash)
      name = hash['name']
      matching_versions = []
      @manifest['dependencies'].each do |dependency|
        if dependency['name'] == name
          matching_versions.push(dependency['version'])
        end
      end
      matching_versions.collect(&:to_s).sort.reverse
    end

    def newest_patch_version(dependency)
      current_version = dependency['version']
      name = dependency['name']

      versions_in_manifest = valid_versions(dependency)

      if versions_in_manifest.count > 1
        newest_patch_version = versions_in_manifest.select do |ver|
          same_version_line?(current_version, ver, name)
        end.sort do |ver1, ver2|
          compare_manifest_versions(ver1, ver2, name)
        end.last
      else
        newest_patch_version = current_version || versions_in_manifest.first
      end

      newest_patch_version
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

    def same_version_line?(ver1, ver2, name)
      semver1 = manifest_to_semver(ver1, name)
      semver2 = manifest_to_semver(ver2, name)

      major1, minor1, _ = semver1.split('.')
      major2, minor2, _ = semver2.split('.')

      case name
      when 'node'
        major1 == major2
      else
        major1 == major2 && minor1 == minor2
      end
    end

    def compare_manifest_versions(ver1, ver2, name)
      Gem::Version.new(manifest_to_semver(ver1, name)) <=>
      Gem::Version.new(manifest_to_semver(ver2, name))
    end

    def manifest_to_semver(version, name)
      case name
      when 'dotnet', 'dotnet-framework'
        # needed for ruby 1.9.1 support
        version.gsub('-','.')
      when 'jruby'
        version.match /.*jruby-(.*)/
        $1
      else
        version
      end
    end

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
      ENV['CF_STACK'] || 'cflinuxfs2'
    end
  end
end
