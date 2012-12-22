require 'active_record'

class Entry < ActiveRecord::Base
  belongs_to :user
  has_many :category_entries
  has_many :categories, through: :category_entry
end
