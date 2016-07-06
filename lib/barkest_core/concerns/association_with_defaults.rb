module BarkestCore

  ##
  # This module allows you to define defaults for a model's associations.
  #
  # While models can be setup with static defaults, this allows you to
  # provide dynamic defaults.  You must define the +association_defaults+ method
  # within the association block for it to work though.  This method should process
  # the attributes in whatever way it needs.  In the example below, we would actually
  # want to look for +org+ and +access+ attributes before overriding the +org_id+ and
  # +access_id+ attributes.
  #
  # This method will override the +new+, +build+, +create+, and +create!+ methods
  # of the association to ensure the dynamic defaults are processed properly.
  #
  #     class User
  #       ...
  #       has_many :accesses, ->{ extending BarkestCommon::AssociationWithDefaults } do
  #         def association_defaults(attributes = {})
  #           {
  #             org_id: proxy_association.owner.current_organization.id,
  #             access_id: Access.default.id
  #           }.merge(attributes || {})
  #         end
  #       end
  #       ...
  #     end
  #
  module AssociationWithDefaults
    #  def association_defaults(attributes = {})
    #   attributes[:some_value] ||= some_default
    #   attributes
    #  end

    def new(attributes = {})
      super association_defaults(attributes)
    end

    def build(*args)
      args << {} if args.blank?
      args = args.map { |a| association_defaults(a) }
      super(*args)
    end

    def create(attributes = {})
      super association_defaults(attributes)
    end

    def create!(attributes = {})
      super association_defaults(attributes)
    end
  end
end


