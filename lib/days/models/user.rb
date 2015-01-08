require 'active_record'
require 'sequel'
require 'days/models/base'

module Days
  class User < ActiveRecord::Base
    has_secure_password

    attr_accessible :login_name, :name, :password, :password_confirmation

    validates_uniqueness_of :login_name
    validates_presence_of :login_name, :name

    has_many :entries, class_name: 'Days::Entry'
  end

  module Models
    class User < Base
      one_to_many :entries

      def validate
        super
        validates_presence [:login_name, :name]
        validates_unique :login_name
      end
    end
  end
end
