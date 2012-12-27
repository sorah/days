require 'active_record'

module Days
  class User < ActiveRecord::Base
    has_secure_password

    has_many :entries, class_name: 'Days::Entry'
  end
end
