BarkestCore::InstallGenerator.class_eval do
  ##
  # Patches the ApplicationMailer class to inherit from BarkestCore::ApplicationMailer.
  def patch_application_mailer
    app_file = 'app/mailers/application_mailer.rb'
    dest_source = '::BarkestCore::ApplicationMailerBase'

    if File.exist?(app_file)
      regex = /^(?<NAME>\s*class ApplicationMailer\s*<\s*)(?<ORIG>\S+)\s*(?<COMMENT>#.*)?$/

      found = false
      changed = false

      lines = File.read(app_file).split("\n").map do |line|
        match = regex.match(line)
        found = true if match
        if match && match['ORIG'] != dest_source
          changed = true
          "#{match['NAME']}#{dest_source} # #{match['ORIG']} #{match['COMMENT']}"
        else
          line
        end
      end

      raise MissingApplicationMailer.new('ApplicationMailer class not found') unless found

      if changed
        if ask_for_bool("Your ApplicationMailer does not currently inherit from BarkestCore.\nWould you like to change this?", true)
          perform "> updating '#{app_file}'..." do
            File.write app_file, lines.join("\n")
          end
        else
          say "> '#{app_file}' is unchanged.", :bright_green
        end
      else
        say "> '#{app_file}' is good.", :bright_green
      end

    else

      if ask_for_bool("Your application is missing an ApplicationMailer.\nWould you like to create one?", true)
        perform "> creating '#{app_file}'..." do
          File.write app_file, <<-APPMLR
class ApplicationMailer < #{dest_source}
  # This is your application mailer, it inherits functionality from BarkestCore.
end
          APPMLR
        end
      end

    end
  end
end