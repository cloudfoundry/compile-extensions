#!/usr/bin/env ruby
#Building staticfile-buildpack
begin
	version_number = nil
	Dir.chdir('staticfile-buildpack') do
		raise "Buildpack Packager failed" unless system("buildpack-packager --cached")

		#Uploading staticfile-buildpack
		version_number = File.read('VERSION')
		name_of_static_file = "staticfile_buildpack-cached-v" + version_number + ".zip"
		puts "BuildPack: cf create-buildpack staticfile_buildpack_bp_version_changing #{name_of_static_file} 1"
		raise "Buildpack upload failed" unless system("cf create-buildpack staticfile_buildpack_bp_version_changing #{name_of_static_file} 1")

	end

	#Application push
	Dir.chdir('staticfile_app') do
		raise "App push failed" unless system("cf push bp_version_changing -b staticfile_buildpack_bp_version_changing")
	end

	#Make temp copy of staticfile-buildpack
	raise "Copy failed" unless system("cp -r staticfile-buildpack staticfile-buildpack-temp")

	Dir.chdir('staticfile-buildpack-temp') do
		array_of_symver = version_number.split('.')
		new_patch_version = array_of_symver.last.to_i + 1
		new_version = array_of_symver[0] + "." + array_of_symver[1] + "." + new_patch_version.to_s
		File.write('VERSION', new_version)

		raise "Buildpack Packager failed" unless system("buildpack-packager --cached")

		#Uploading staticfile-buildpack
		version_number = File.read('VERSION')
		name_of_static_file = "staticfile_buildpack-cached-v" + version_number + ".zip"
		raise "Buildpack update failed" unless system("cf update-buildpack staticfile_buildpack_bp_version_changing -p #{name_of_static_file}")
	end


	#Application push
	Dir.chdir('staticfile_app') do
		raise "Second app push failed" unless system("cf push bp_version_changing -b staticfile_buildpack_bp_version_changing")
	end

ensure
	system("cf delete-buildpack staticfile_buildpack_bp_version_changing -f")
	require 'fileutils'
	FileUtils.rm_rf('staticfile-buildpack-temp')
end

