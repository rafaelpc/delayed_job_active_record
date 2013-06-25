require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'logger'
require 'rspec'

require 'delayed_job_active_record'
require 'delayed/backend/shared_spec'

Delayed::Worker.logger = Logger.new('/tmp/dj.log')
ENV['RAILS_ENV'] = 'test'

config = YAML.load(File.read('spec/database.yml'))
db_adapter = ENV['CI_DB_ADAPTER'] || 'sqlite3'
ActiveRecord::Base.establish_connection config[db_adapter]
ActiveRecord::Base.logger = Delayed::Worker.logger
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority, :default => 0
    table.integer  :attempts, :default => 0
    table.text     :handler
    table.text     :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.datetime :failed_at
    table.string   :locked_by
    table.string   :queue
    table.string   :digest
    table.timestamps
  end

  add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
  add_index :delayed_jobs, [:digest], :name => 'delayed_jobs_digest'

  create_table :stories, :primary_key => :story_id, :force => true do |table|
    table.string :text
    table.boolean :scoped, :default => true
  end
end

# Purely useful for test cases...
class Story < ActiveRecord::Base
  self.primary_key = :story_id
  def tell; text; end
  def whatever(n, _); tell*n; end
  default_scope where(:scoped => true)

  handle_asynchronously :whatever
end

class AllowDuplicationJob < SimpleJob
  def allow_duplication; true; end
end

class DigestibleJob < SimpleJob
  def digestible; "something"; end
end

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)
