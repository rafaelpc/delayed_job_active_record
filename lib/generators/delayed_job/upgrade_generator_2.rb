require 'generators/delayed_job/delayed_job_generator'
require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

# Extend the DelayedJobGenerator so that it creates an AR migration
module DelayedJob
  class UpgradeGenerator2 < ::DelayedJobGenerator
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'upgrade_migration_2.rb', 'db/migrate/add_digest_to_delayed_jobs.rb'
    end
  end
end
