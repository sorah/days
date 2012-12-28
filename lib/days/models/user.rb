require 'active_record'

module Days
  class User < ActiveRecord::Base
    has_secure_password

    attr_accessible :login_name, :name, :password, :password_confirmation

    validates_uniqueness_of :login_name
    validates_presence_of :login_name, :name

    has_many :entries, class_name: 'Days::Entry'
  end
end
