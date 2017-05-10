module CompileExtensions
  class EolDeprecations
    def initialize(manifest)
      @manifest = manifest
    end

    def deprecation(dependency)
      @eol_dates ||= Array(@manifest['dependency_deprecation_dates']).map do |d|
        Deprecation.new(d)
      end
      @eol_dates.detect { |d| d.match?(dependency) }
    end

    class Deprecation
      attr_reader :name, :version_line, :date, :link
      def initialize(hash)
        @name = hash['name']
        @match = Regexp.new(hash['match'])
        @version_line = hash['version_line']
        @date = hash['date']
        @link = hash['link']
      end

      def match?(dependency)
        return false unless dependency
        @name == dependency['name'] && @match.match(dependency['version'])
      end

      def warning?
        @date && (@date.to_date - Date.today).to_i <= 30
      end
    end
  end
end
