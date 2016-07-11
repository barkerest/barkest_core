BarkestCore::InstallGenerator.class_eval do
  ##
  # Patches routes.rb to include BarkestCore::Engine and session management paths.
  def patch_routes
    route_file = 'config/routes.rb'

    unless File.exist?(route_file)

      if ask_for_bool("Your application is missing a 'routes.rb' configuration file.\nWould you like to create one?", true)
        perform '> creating \'routes.rb\'...' do
          File.write route_file, <<-DEFRTS
Rails.application.routes.draw do
  # Enter your routes in this file.
end
          DEFRTS
        end
      else
        tell '> missing \'routes.rb\'.', :yellow
        return
      end

    end

    lines = File.exist?(route_file) ? File.read(route_file).split("\n") : ['Rails.application.routes.draw do','end']

    insert_at = -1

    regex = /.*\.routes\.draw\s+do\s*(#.*)?$/
    lines.each_with_index do |line, index|
      if regex.match(line)
        insert_at = index + 1
        break
      end
    end

    raise MissingRoutes.new('routes not found') unless insert_at >= 0

    changed = false

    core_regex = /^\s*barkest_core([\s\(]+(?<OPTIONS>[^\s\)#][^\)#]+)\)?)?\s*(?<COMMENT>#.*)?$/
    root_regex = /^\s*root([\s\(]+(?<OPTIONS>[^\s\)#][^\)#]+)\)?)?\s*(?<COMMENT>#.*)?$/
    core = nil
    root = nil

    lines.each_with_index do |line, index|
      line = line.strip
      if (match = core_regex.match(line))
        opts = match['OPTIONS'].to_s.strip
        core = {
            index: index,
            path: if (path_offset = opts.index(':path'))
                    opts[path_offset..-1].partition('=>')[2].partition(',')[0].strip[1...-1]
                  elsif (path_offset = opts.index('path:'))
                    opts[path_offset..-1].partition(':')[2].partition(',')[0].strip[1...-1]
                  else
                    opts[1...-1]  # strip '...' or "..." to ...
                  end.to_s
        }
      elsif (match = root_regex.match(line))
        opts = match['OPTIONS'].to_s.strip
        root = {
            index: index,
            path: opts[1...-1].to_s # strip '...' or "..." to ...
        }
      end
    end

    unless core
      if ask_for_bool('Would you like to add the \'barkest_core\' routes to your application?', true)
        path = ask_for_string('What path prefix would you like?', '/')
        lines.insert insert_at, "\n  barkest_core #{path.inspect}"
        changed = true
      end
    end

    unless root
      if ask_for_bool("Your application is missing a root route.\nWould you like to add one?", true)
        path = ask_for_string('What controller#action would you like for your root route?', 'test_access#allow_anon')
        lines.insert insert_at, "\n  root #{path.inspect}"
        changed = true
      end
    end

    if changed
      perform '> updating \'routes.rb\'...' do
        File.write route_file, lines.join("\n")
      end
    else
      tell '> \'routes.rb\' is good.', :bright_green
    end

  end
end