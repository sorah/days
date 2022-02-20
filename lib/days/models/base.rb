require 'active_record'
require 'kaminari/activerecord'

module Days
  module Models
    class Base < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
