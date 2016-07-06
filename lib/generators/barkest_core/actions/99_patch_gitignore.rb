BarkestCore::InstallGenerator.class_eval do
  ##
  # Patches .gitignore to ignore *.yml configuration files.
  def patch_gitignore
    file = '.gitignore'

    dummy = Dir.exist?('test/dummy')

    if File.exist?(file)
      lines = File.read(file).split("\n")

      protect_cfg = false
      protect_dummy_cfg = false

      cfg_regex = /^\s*config\/\*.yml\s*$/
      dummy_cfg_regex = /^\s*test\/dummy\/config\/\*.yml\s*$/

      lines.each do |line|
        protect_cfg = true if cfg_regex.match(line)
        protect_dummy_cfg = true if dummy_cfg_regex.match(line)
      end

      changed = false
      unless protect_cfg
        if ask_for_bool("Your .gitignore does not protect your YAML configuration files.\nWould you like to add a line to protect them?", true)
          lines << 'config/*.yml'
          changed = true
        end
      end

      if dummy && !protect_dummy_cfg
        if ask_for_bool("Your .gitignore does not protect your dummy application's YAML configuration files.\nWould you like to add a line to protect them?", true)
          lines << 'test/dummy/config/*.yml'
          changed = true
        end
      end

      if changed
        perform '> updating \'.gitignore\'...' do
          File.write file, lines.join("\n")
        end
      else
        say '> \'.gitignore\' is good.', :bright_green
      end

    else
      if ask_for_bool('Would you like to create a .gitignore that protects your YAML files?', true)
        perform '> creating \'.gitignore\'...' do
          contents = %w(.bundle/ .sass-cache/ config/*.yml db/*.sqlite3 db/*.sqlite3-journal doc/ log/*.log pkg/ tmp/ vendor/bundle/)
          contents += contents.map{|v| "test/dummy/#{v}"} if dummy

          File.write file, contents.join("\n")
        end
      end
    end
  end
end