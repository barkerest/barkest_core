BarkestCore::InstallGenerator.class_eval do
  MissingApplicationController = Class.new(::Thor::Error)

  ##
  # Patches the ApplicationController class to inherit from BarkestCore::ApplicationController.
  def patch_application_controller
    app_file = 'app/controllers/application_controller.rb'
    dest_source = '::BarkestCore::ApplicationControllerBase'

    if File.exist?(app_file)
      regex = /^(?<NAME>\s*class ApplicationController\s*<\s*)(?<ORIG>\S+)\s*(?<COMMENT>#.*)?$/

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

      raise MissingApplicationController.new('ApplicationController class not found') unless found

      if changed
        if ask_for_bool("Your ApplicationController does not currently inherit from BarkestCore.\nWould you like to change this?", true)
          perform "> updating '#{app_file}'..." do
            File.write app_file, lines.join("\n")
          end
        else
          tell "> '#{app_file}' is unchanged.", :bright_green
        end
      else
        tell "> '#{app_file}' is good.", :bright_green
      end

    else

      if ask_for_bool("Your application is missing an ApplicationController.\nWould you like to create one?", true)
        perform "> creating '#{app_file}'..." do
          File.write app_file, <<-APPCTRLR
class ApplicationController < #{dest_source}
  # This is your application controller, it inherits functionality from BarkestCore.
end
          APPCTRLR
        end
      end

    end
  end
end