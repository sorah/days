require 'sequel'

module Days
  module Models
    # Sequel::Model requires active database connection on class inheritance.
    # What?? https://groups.google.com/forum/#!topic/sequel-talk/0x_AyzIIGUo
    def self.dummy_connection
      # on memory
      @dummy_connection ||= Sequel.sqlite
    end
    class Base < Sequel::Model(self.dummy_connection[:base])
    end
  end
end
