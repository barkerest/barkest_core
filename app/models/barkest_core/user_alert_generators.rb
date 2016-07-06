module BarkestCore
  ##
  # A repository for user alert generators.
  #
  # Register any alert generators that you want to give the user automatically at login.
  #
  class UserAlertGenerators

    ##
    # Enumerates all of the generators that have been registered.
    #
    # Yields the +type+ and +generator+.
    def self.each(&block)
      return unless block_given?
      list.each do |type,generators|
        generators.each do |generator|
          yield type, generator
        end
      end
    end

    ##
    # Gets all of the generators that have been registered.
    #
    # This list does not include the type.
    def self.all
      list.values.flatten.freeze
    end

    ##
    # Gets a subset of the generators that have been registered.
    #
    # Provide the type of generators you would like to return.
    def self.[](type)
      type ||= :info
      type = type.to_sym
      (list[type] || []).freeze
    end

    ##
    # Registers an alert generator.
    #
    # The generator shold be designed to take a User model as an argument.
    def self.register(type = nil, &block)
      type ||= :info
      type = type.to_sym
      list[type] ||= []
      list[type] << block
    end

    private

    def self.list
      @list ||= {}
    end

  end
end
