BarkestCore::InstallGenerator.class_eval do
  ##
  # Patches the default layouts to inherit from the BarkestCore layouts.
  def patch_layouts
    {
        'app/views/layouts/application.html.erb' => 'layouts/barkest_core/application',
        'app/views/layouts/mailer.html.erb' => 'layouts/barkest_core/html_mailer',
        'app/views/layouts/mailer.text.erb' => 'layouts/barkest_core/text_mailer'
    }.each do |file,layout|

      if File.exist?(file)
        regex = /<%=\s+render[\s\(]+['"]#{layout}['"][\)\s]*%>/
        if regex.match(File.read(file))
          tell "> '#{file}' is good.", :bright_green
        else
          if ask_for_bool("Your '#{file}' layout does not reference the BarkestCore layout.\nWould you like to change it to use the BarkestCore layout?", true)
            perform "> updating '#{file}'..." do
              File.write file, "<%= render '#{layout}' %>\n"
            end
          else
            tell "> '#{file}' is unchanged.", :bright_green
          end
        end
      else
        if ask_for_bool("Your application is missing '#{file}'.\nWould you like to add one?", true)
          perform "> creating '#{file}'..." do
            File.write file, "<%= render '#{layout}' %>\n"
          end
        else
          tell "> '#{file}' is missing.", :yellow
        end
      end

    end
  end
end