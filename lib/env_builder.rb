class EnvBuilder

  def initialize(deps_dir, deps_prefix)
    @deps_dir = deps_dir
    @deps_prefix = deps_prefix
  end

 def path
   existing_sub_dirs('bin').join(':')
 end

  def ld_library_path
    existing_sub_dirs('lib').join(':')
  end

  def env
    Dir["#{@deps_dir}/*/env/*"].sort.map do |file|
      data = File.read(file)
      "#{File.basename(file)}=#{data}"
    end
  end

  private

  def existing_sub_dirs(sub_dir_name)
    Dir.chdir(@deps_dir) do
      Dir["*/#{sub_dir_name}"].sort.reverse.map do |dir|
        "#{@deps_prefix}/#{dir}"
      end
    end
  end
end


