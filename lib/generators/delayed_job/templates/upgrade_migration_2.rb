class AddDigestToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :digest, :string, :limit => 40
    add_index :delayed_jobs, [:digest], :name => 'delayed_jobs_digest'
  end

  def self.down
  	remove_index :delayed_jobs, :name => 'delayed_jobs_digest'
    remove_column :delayed_jobs, :digest
  end
end
