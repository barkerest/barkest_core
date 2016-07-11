BarkestCore::InstallGenerator.class_eval do
  ##
  # Patches the db/seeds to allow multiple seeding files and includes the seeds necessary for BarkestCore.
  def patch_seeds
    files = Dir.glob(File.expand_path('../../../../../db/{seeds.rb,seeds/*.rb}', __FILE__))

    unless Dir.exists?('db/seeds')
      if ask_for_bool("Your application does not currently have a 'db/seeds' directory.\nBarkestCore can alter your application to make use of multiple seeding files.\nDo you want to create the 'db/seeds' directory to enable this behavior?", true)
        perform '> creating \'db/seeds\' directory.' do
          Dir.mkdir 'db/seeds'
        end
      else
        tell "> 'db/seeds' directory is missing.", :yellow
        return
      end
    end

    source = files.find{|v| v[-11..-1] == 'db/seeds.rb'}
    prefix_dir_len = source.length - 11
    dest = source[prefix_dir_len..-1]

    if File.exist?(dest)
      current_contents = File.read(dest).strip

      # if 'seeds.rb' defines a 'Seeds' class, then we assuming it to be a seeder.
      is_seeder = false
      current_contents.split("\n").each do |line|
        is_seeder = true if /^\s*class\s+Seeds(\s.*)?$/.match(line)
      end

      unless is_seeder
        if ask_for_bool('Would you like to move your \'db/seeds.rb\' file into the \'db/seeds\' directory?', true)
          perform "> moving '#{dest}' into 'db/seeds' directory..." do
            File.rename dest, 'db/seeds/' + File.basename(dest)
          end
        else
          tell "> 'db/seeds.rb' is not being moved.", :yellow
        end
      end
    end

    files.each do |source|
      dest = source[prefix_dir_len..-1]
      contents = File.read(source)

      if File.exist?(dest) && File.read(dest).strip == contents.strip
        tell "> '#{dest}' is good.", :bright_green
      else
        if !File.exist?(dest) || ask_for_bool("Would you like to update '#{dest}'?", true) == false
          perform "> #{File.exist?(dest) ? 'creating' : 'updating'} \'#{dest}\'..." do
            File.write dest, contents
          end
        else
          tell "> '#{dest}' is unchanged.", :bright_green
        end
      end
    end
  end
end