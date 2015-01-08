require 'active_record'
require 'days/models/base'

module Days
  class Category < ActiveRecord::Base
    attr_accessible :name

    validates_presence_of :name
    validates_uniqueness_of :name

    has_and_belongs_to_many :entries, class_name: 'Days::Entry'
  end

  module Models
    class Category < Base
      many_to_many :entries

      def validate
        super
        validates_presence :name
        validates_unique :name
      end
    end
  end
end
