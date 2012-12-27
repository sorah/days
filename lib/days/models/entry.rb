require 'active_record'

module Days
  class Entry < ActiveRecord::Base
    belongs_to :user, class_name: 'Days::User'
    has_and_belongs_to_many :categories, class_name: 'Days::Category'
  end
end
