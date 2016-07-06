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
    establish_connection BarkestCore.db_config
  end

end
