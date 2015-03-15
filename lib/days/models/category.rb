require 'days/models/base'

module Days
  class Category < ActiveRecord::Base
    attr_accessible :name

    validates_presence_of :name
    validates_uniqueness_of :name

    has_and_belongs_to_many :entries, class_name: 'Days::Entry'
  end
end
