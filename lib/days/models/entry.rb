require 'active_record'

class Entry < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :categories
end
