class EnvBuilder

  def initialize(deps_dir, deps_prefix)
    @deps_dir = deps_dir
    @deps_prefix = deps_prefix
  end

 def path
    join_existing_sub_dirs('bin')
 end

  def ld_library_path
    join_existing_sub_dirs('lib')
  end

  private

  def join_existing_sub_dirs(sub_dir_name)
    val = ""

    Dir.chdir(@deps_dir) do
      Dir['*'].sort.reverse.each do |dir|
        sub_dir = File.join(@deps_dir, dir, sub_dir_name)

        if File.exist?(sub_dir)
          val += "#{@deps_prefix}/#{dir}/#{sub_dir_name}:"
        end
      end
    end

    val.chomp(':')
  end
end


