libraries_dir = ENV['LIBRARIES_HOME']
if not libraries_dir.nil?
  symlinked_bundler_setup_rb_pattern = File.expand_path('*-bundler-setup.rb', libraries_dir)

  Dir.glob(symlinked_bundler_setup_rb_pattern) do |symlinked_bundler_setup_rb|
    require_relative(symlinked_bundler_setup_rb)
  end
end

gems_lib_dir = File.expand_path('gems/lib', __dir__)
if not $LOAD_PATH.include?(gems_lib_dir)
  $LOAD_PATH.unshift(gems_lib_dir)
end

require 'bundler/setup'
