require_relative 'app'
require 'days/models/base'
require 'logger'
require 'settingslogic'

module Days
  class Config < Settingslogic
    def self.namespace(value = nil)
      if value
        @namespace = value
      else
        @namespace
      end
    end

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

    def run_scripts
      (self[:scripts] || []).each do |_|
        path = File.expand_path(_, self[:root])
        instance_eval File.read(path), path, 1
      end
    end

    def establish_db_connection(force=false, base: ActiveRecord::Base)
      if Days::App.environment.to_sym == :development && (self.has_key?(:activerecord_log) ? self.activerecord_log == true : true)
        base.logger = Logger.new($stdout)
      end

      begin
        raise ActiveRecord::ConnectionNotEstablished if force
        return base.connection
      rescue ActiveRecord::ConnectionNotEstablished
        base.establish_connection(self['database'] ? Hash[self.database] : ENV["DATABASE_URL"])
        retry
      end
    end
  end
end
