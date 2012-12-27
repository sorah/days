require 'active_record'

module Days
  class Category < ActiveRecord::Base
    has_and_belongs_to_many :entries, class_name: 'Days::Entry'
  end
end
