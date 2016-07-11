BarkestCore::InstallGenerator.class_eval do
  ##
  # Runs the rake task to install the BarkestCore migrations.
  def copy_migrations
    tell '=' * 79
    if ask_for_bool('Would you like to install the BarkestCore database migrations?', true)
      tell 'Copying database migrations...' unless options.quiet?

      ts = Time.now.strftime('%Y%m%d%H%M%S').to_i
      ext = '.barkest_core.rb'

      unless Dir.exist?('db/migrate')
        perform '> creating \'db/migrate\' directory...' do
          Dir.mkdir 'db/migrate'
        end
      end

      existing = Dir.glob("db/migrate/*#{ext}")

      find_existing = Proc.new do |file|
        fn = File.basename(file)[0...-3].partition('_')[2]

        existing.find do |ex|
          fn == File.basename(ex)[0...(-ext.length)].partition('_')[2]
        end
      end

      Dir.glob(File.expand_path('../../../../../db/migrate/*.rb', __FILE__)).each do |file|
        target_file = find_existing.call(file)
        contents = File.read(file)
        if target_file
          cur_contents = File.read(target_file)
          if cur_contents.strip == contents.strip
            tell "> '#{target_file}' is good.", :bright_green
          else
            perform "> updating '#{target_file}'..." do
              File.write target_file, contents
            end
          end
        else
          target_file = "db/migrate/#{ts}_#{File.basename(file)[0...-3].partition('_')[2]}#{ext}"
          ts += 1
          perform "> creating '#{target_file}'..." do
            File.write target_file, contents
          end
        end
      end

    end
  end
end