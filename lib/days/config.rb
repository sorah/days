require_relative 'app'
require 'active_record'
require 'logger'
require 'settingslogic'

module Days
  class Config < Settingslogic
    namespace App.environment.to_s

    def initialize(hash_or_file = {}, section = nil)
      super
      if section.nil?
        if String === hash_or_file
          self[:root] = File.dirname(hash_or_file)
        else
          self[:root] = "."
        end

        self['database'].tap do |hash|
          next unless hash
          if hash['adapter'] == 'sqlite3' && /^\// !~ hash['database']
            hash['database'] = File.join(self.root, hash['database'])
          end
        end
      end
    end

    def establish_db_connection(force=false)
      if !self.has_key?(:activerecord_log) || self.activerecord_log == true
        ActiveRecord::Base.logger = Logger.new($stdout)
      end

      begin
        raise ActiveRecord::ConnectionNotEstablished if force
        return ActiveRecord::Base.connection
      rescue ActiveRecord::ConnectionNotEstablished
        ActiveRecord::Base.establish_connection(self['database'] ? Hash[self.database] : ENV["DATABASE_URL"])
        retry
      end
    end
  end
end
