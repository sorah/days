require 'active_record'

class Category < ActiveRecord::Base
  has_and_belongs_to_many :entries
end
