require 'active_record'

class User < ActiveRecord::Base
  has_secure_password

  has_many :entries
end
