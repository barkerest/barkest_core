require 'rubygems'

module Barkest

  ##
  # Installs Barkest modules into an application.
  class InstallGenerator < Rails::Generators::Base

    desc 'Installs the Barkest functionality into your application.'

    def install_modules
      installers.each do |inst|
        sep = '-' + ('=---' * 19) + '=-'
        tell "#{sep}\nProcessing #{inst.class}\n#{sep}", :bold
        inst.public_methods(false).each { |method| inst.send(method) }
      end
    end

    private

    def installers
      @installers ||= find_modules
    end

    def find_modules
      ret = []
      # generator is run from root of app directory
      Gem::Specification.each do |gem|
        if gem.name.index('barkest_') == 0
          installer =
              begin
                # ensure the gem has been loaded.
                require gem.name
                # then ensure the install_generator (if any) has been loaded.
                inst_path = "generators/#{gem.name}/install_generator"
                begin
                  require inst_path
                  # finally load the class and generate an instance.
                  klass_name = "#{gem.name.camelcase}::InstallGenerator"
                  begin
                    klass = Object.const_get(klass_name)
                    klass.new
                  rescue NameError
                    puts "Failed to load '#{klass_name}'."
                    nil
                  end
                rescue LoadError
                  puts "Failed to load '#{inst_path}'."
                  nil
                end
              rescue LoadError
                puts "Failed to load '#{gem.name}'."
                nil
              end
          ret << installer unless installer.nil?
        end
      end

      ret.sort do |a,b|
        ka = a.class.name
        kb = b.class.name

        # ensure Core installers run first.
        kac = ka.index('BarkestCore::') == 0
        kbc = kb.index('BarkestCore::') == 0

        if kac && kbc
          ka <=> kb
        elsif kac
          -1
        elsif kbc
          1
        else
          ka <=> kb
        end
      end

      ret
    end

  end
end
