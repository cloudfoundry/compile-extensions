require 'fileutils'

class EnvBuilder

  def initialize(deps_dir, deps_prefix)
    @deps_dir = deps_dir
    @deps_prefix = deps_prefix
  end

 def path
   existing_sub_dirs('bin').join(':')
 end

 def include_path
   existing_sub_dirs('include').join(':')
 end

 def pkgconfig
   existing_sub_dirs('pkgconfig').join(':')
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

  def copy_profile_d_scripts(build_dir)
    output_dir = File.join(build_dir, ".profile.d")
    FileUtils.mkdir_p(output_dir)

    Dir.chdir(@deps_dir) do
      Dir['*/profile.d/*'].each do |script_location|
        idx, _, name = script_location.split("/")
        output_file = File.join(output_dir, "#{idx}-#{name}")
        FileUtils.cp(script_location, output_file)
      end
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


