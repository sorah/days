require 'logger'

module Days
  module Migrator
    MIGRATIONS_DIR =  "#{__dir__}/migrations"
    def self.start(config, options = {})
      Sequel.extension :migration

      if config.db.table_exists?(:schema_migrations) &&
           !config.db.schema(:schema_migrations).assoc(:filename)
        puts "=> Converting Rails' `schema_migrations` for sequel" unless options[:quiet]

        config.db.alter_table(:schema_migrations) { add_column :filename, String }

        migrations = Dir[File.join(MIGRATIONS_DIR, '*.rb')].map{ |_| File.basename(_) }

        config.db[:schema_migrations].each do |row|
          filename = migrations.find{ |_| _.start_with?("#{row[:version]}_") }

          config.db[:schema_migrations].where(version: row[:version]).update(filename: filename)
        end

        config.db.alter_table(:schema_migrations) do
          drop_column :version
          add_primary_key [:filename]
        end
      end

      if options[:version]
        Sequel::Migrator.run config.db, MIGRATIONS_DIR, target: options[:version]
      else
        Sequel::Migrator.run config.db, MIGRATIONS_DIR
      end
    end
  end
end
