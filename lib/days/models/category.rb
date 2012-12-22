require 'active_record'

class Category < ActiveRecord::Base
  has_many :category_entries
  has_many :entries, through: :category_entries
end
