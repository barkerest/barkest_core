
module Barkest

  ##
  # Installs Barkest modules into an application.
  class InstallGenerator < Rails::Generators::Base

    desc 'Installs the Barkest functionality into your application.'

    def install_modules
      barkest_installers.each do |inst|
        sep = '-' + ('=---' * 19) + '=-'
        tell "#{sep}\nProcessing #{inst.class}\n#{sep}", :bold
        inst.public_methods(false).each { |method| inst.send(method) }
      end
    end

    private

    def barkest_installers
      @barkest_installers ||=
          begin
            ret = []
            Object.constants.each do |const|
              mod = Object.const_get(const)

              if mod.is_a?(Module)
                if mod.name != 'Barkest' && mod.name.index('Barkest') == 0
                  path = "generators/#{mod.name.underscore}/install_generator"
                  item =
                      begin
                        require path
                        mod.const_get('InstallGenerator')
                      rescue LoadError
                        nil
                      rescue NameError
                        nil
                      end
                  ret << item.new if item
                end
              end
            end
            ret
          end
    end
  end
end
