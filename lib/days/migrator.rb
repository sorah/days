module Days
  module Migrator
    def self.start(config, options = {})
      require 'active_record'
      require 'active_support/core_ext/class/attribute_accessors.rb'
      require 'active_record/schema_dumper'

      config.establish_db_connection()
      orig_logger = ActiveRecord::Base.logger
      begin
        ActiveRecord::Base.logger = nil unless options[:show_sql]
        ActiveRecord::Migration.verbose = options[:verbose]

        migration_paths = [
          config[:migration_path] || "#{config.root}/db/migrate",
          File.expand_path(File.join(__FILE__, '..', 'migrate'))
        ]
        ActiveRecord::Migrator.migrate(migration_paths, options[:version]) do |migration|
          options[:scope].blank? || (options[:scope] == migration.scope)
        end

        schema_file = config[:schema] || "#{config.root}/db/schema.rb"
        File.open(schema_file, "w:utf-8") do |io|
          ActiveRecord::SchemaDumper.dump ActiveRecord::Base.connection, io
        end

        self
      ensure
        ActiveRecord::Base.logger = orig_logger
      end
    end
  end
end
