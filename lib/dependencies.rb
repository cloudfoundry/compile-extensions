require 'yaml'

class Dependencies
  def find_matching_dependency(uri)
    manifest = YAML.load_file('manifest.yml')
    manifest['dependencies'].find do |dependency|
      dependency['original'] == uri
    end
  end

  def find_translated_dependency(uri)
    matching_dependency = find_matching_dependency(uri)

    if matching_dependency.nil?
      puts "DEPENDENCY_MISSING_IN_MANIFEST: #{uri}"
      exit 1
    end

    matching_dependency['xlated']
  end
end
