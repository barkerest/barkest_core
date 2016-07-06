# this shouldn't be necessary, but engines seem to have a few weak spots.
require 'will_paginate/active_record'

module BarkestCore

  ##
  # This class serves as a base class for other models.
  #
  # This way we can guarantee that all of our models can use an explicit configuration
  # when desirable.
  class DbTable < ActiveRecord::Base
    self.abstract_class = true

    # Ensure that we only establish a new connection if needed.
    unless BarkestCore.db_config.symbolize_keys == ActiveRecord::Base.connection_config.symbolize_keys
      establish_connection BarkestCore.db_config
    end

  end

end
