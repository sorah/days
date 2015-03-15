 require 'active_record'
 require 'protected_attributes'
 require 'active_record/mass_assignment_security'

module Days
  module Models
    class Base < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
