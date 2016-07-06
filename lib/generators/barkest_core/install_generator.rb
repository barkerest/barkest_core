require 'io/console'

module BarkestCore

  ##
  # Installs BarkestCore into an application.
  class InstallGenerator < Rails::Generators::Base

    MissingApplicationController = Class.new(::Thor::Error)
    MissingApplicationMailer = Class.new(::Thor::Error)


    desc 'Installs the BarkestCore functionality into your application.'

    # actions are stored in the 'actions' directory.

    private

    def erb_read(file)
      ERB.new(File.read(file), 0).result
    end

    def say(message, color = nil)
      open = ''
      close = ''
      if color
        open = "\033[0"
        close = "\033[0m"
        open += case color.to_sym
                  when :black
                    ';30'
                  when :dark_grey, :dark_gray
                    ';30;1'
                  when :red, :dark_red
                    ';31'
                  when :bright_red
                    ';31;1'
                  when :green, :dark_green
                    ';32'
                  when :bright_green
                    ';32;1'
                  when :gold, :dark_yellow
                    ';33'
                  when :yellow
                    ';33;1'
                  when :dark_blue
                    ';34'
                  when :blue
                    ';34;1'
                  when :dark_magenta, :violet, :purple
                    ';35'
                  when :magenta, :pink
                    ';35;1'
                  when :dark_cyan, :teal
                    ';36'
                  when :cyan, :aqua
                    ';36;1'
                  when :light_gray, :gray, :light_grey, :grey
                    ';37'
                  when :white
                    ';37;1'
                  else
                    ''
                end + 'm'

      end

      puts open + message + close unless options.quiet?
    end

    def trimq(question)
      question = question.to_s.strip
      if question[-1] == '?' || question[-1] == ':'
        question = question[0...-1]
      end
      question
    end

    def ask_for_bool(question, default = false)
      return default if options.quiet?

      print "#{trimq(question)} [#{default ? 'Y/n' : 'y/N'}]? "

      answer = STDIN.gets.strip.upcase[0]

      return default if answer.blank?

      answer == 'Y'
    end

    def ask_for_string(question, default = '', valid = nil)
      return default if options.quiet?

      loop do
        print "#{trimq(question)} [#{default}] (. to clear)? "

        answer = STDIN.gets.strip

        return '' if answer == '.'
        return default if answer.blank?

        if valid && valid.respond_to?(:call)
          return answer if valid.call(answer)
        elsif valid && valid.respond_to?(:include?)
          return answer if valid.include?(answer)
        else
          return answer
        end

        puts "Entered value (#{answer}) is invalid."
        unless valid.respond_to?(:call)
          puts "Valid values are #{valid.inspect}."
        end
      end

    end

    def ask_for_int(question, default = 0, valid = nil)
      return default if options.quiet?

      loop do
        print "#{question} [#{default}]? "

        answer = STDIN.gets.strip

        return default if answer.blank?

        answer = answer.to_i

        if valid && valid.respond_to?(:call)
          return answer if valid.call(answer)
        elsif valid && valid.respond_to?(:include?)
          return answer if valid.include?(answer)
        else
          return answer
        end

        puts "Entered value (#{answer}) is invalid."
        unless valid.respond_to?(:call)
          puts "Valid values are #{valid.inspect}."
        end
      end
    end

    def ask_for_secret(question, default = '')
      return default if options.quiet?

      print "#{question} [enter to keep, . to clear]: "

      loop do
        answer1 = STDIN.noecho(&:gets).strip
        puts ''

        return '' if answer1 == '.'
        return default if answer1.blank?

        print 'Enter again to confirm: '
        answer2 = STDIN.noecho(&:gets).strip
        puts ''

        return answer1 if answer2 == answer1

        puts 'Confirmation does not match!'
        print 'Please try again: '
      end
    end

    def input_attributes(target_hash, attribute_list, defaults, hash_key = nil)
      attribute_list.each do |data|
        if data.is_a?(Hash)
          if hash_key && target_hash[hash_key] && data[target_hash[hash_key]].is_a?(Array)
            target_hash = input_attributes(target_hash, data[target_hash[hash_key]], defaults, hash_key)
          end
        elsif data.is_a?(Array)
          field,asker,valid,label,default_override = data
          label ||= field
          def_val = if target_hash[field].nil?
                      if default_override.nil?
                        defaults[field]
                      else
                        default_override
                      end
                    else
                      target_hash[field]
                    end

          answer = if valid
                     send(asker, label, def_val, valid)
                   else
                     send(asker, label, def_val)
                   end

          target_hash[field] = answer
        end
      end
      target_hash
    end

    def configure_the(what, config_file, attributes, hash_key, defaults, *optional_levels)
      say '=' * 79
      if ask_for_bool("Would you like to configure #{what.pluralize}?", true)
        current_config = File.exist?(config_file) ? YAML.load_file(config_file) : {}
        last_level = nil
        levels = ([''] + (optional_levels || [])).uniq
        levels.each do |level|
          if level.blank? || ask_for_bool("Would you like to configure a #{level} #{what.singularize} configuration?", false)
            current_config[level] ||= {} unless level.blank?

            last_env = nil
            %w(test development production).each do |env|
              say "Configure the '#{level.blank? ? '' : (level + ':')}#{env}' environment."
              say '-' * 79

              current = if level.blank?
                          (current_config[env] || {}).dup
                        else
                          (current_config[level][env] || {}).dup
                        end

              if last_env
                if !last_level.blank? && ask_for_bool("Would you like to use the configuration from the '#{last_level}:#{last_env}' environment to start?", false)
                  current = (current_config[last_level][last_env] || {}).dup
                elsif ask_for_bool("Would you like to use the configuration from the '#{last_env}' environment to start?", false)
                  current = (current_config[last_env] || {}).dup
                end
              end
              current ||= {}

              if current.blank? || ask_for_bool("Do you want to make changes to the '#{level.blank? ? '' : (level + ':')}#{env}' environment?", false)
                current = input_attributes(current, attributes, defaults, hash_key)
              end

              if level.blank?
                current_config[env] = current
              else
                current_config[level][env] = current
              end

              say '-' * 79

              last_env = env
            end
            last_level = level
          end
        end

        perform "> creating '#{config_file}'..." do
          File.write config_file, current_config.to_yaml
        end
      end
    end

    def perform(message, &block)
      say message + (options.pretend? ? ' [pretend]' : ''), :teal
      block.call unless options.pretend?
    end



  end
end

# load the actions
Dir.glob(File.expand_path('../actions/*.rb', __FILE__)).each { |action| require action }
