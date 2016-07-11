BarkestCore::InstallGenerator.class_eval do
  ##
  # Patches application.js and application.css
  def patch_assets
    target = 'barkest_core/application'

    [
        [ 'app/assets/javascripts/application.js', '//=', "// Application.js\n//= require_tree .\n" ],
        [ 'app/assets/stylesheets/application.css', '*=', "/*\n * Application.css\n *= require_tree .\n *= require_self\n */\n" ]
    ].each do |(path, line_tag, def_contents)|

      lines = if File.exist?(path)
                   File.read(path)
                 else
                   def_contents
                 end.split("\n")

      first_tag = -1
      first_pass = true
      loop do
        lines.each_with_index do |line, index|
          if line.strip[0...line_tag.length] == line_tag
            first_tag = index
            break
          end
        end
        if first_tag < 0
          if first_pass
            lines += def_contents.split("\n")
          else
            raise StandardError.new("Failed to locate line starting with '#{line_tag}' in '#{path}'.")
          end
        else
          break
        end
        first_pass = false
      end

      regex = /^\s*#{line_tag.gsub('*',"\\*")}\s*require\s*['"]?#{target}['"]?\s*$/

      tag_index = -1
      lines.each_with_index do |line, index|
        if regex.match(line)
          tag_index = index
          break
        end
      end
      if tag_index < 0
        if ask_for_bool("Would you like to add a reference to BarkestCore in '#{path}'?", true)
          lines.insert first_tag, "#{line_tag} require #{target}"
          perform "> updating '#{path}'..." do
            File.write path, lines.join("\n")
          end
        else
          tell "> '#{path}' is unchanged.", :bright_green
        end
      else
        tell "> '#{path}' is good.", :bright_green
      end
    end
  end
end
