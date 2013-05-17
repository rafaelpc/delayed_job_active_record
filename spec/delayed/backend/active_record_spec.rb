require 'helper'
require 'delayed/backend/active_record'

describe Delayed::Backend::ActiveRecord::Job do
  it_behaves_like 'a delayed_job backend'

  context "db_time_now" do
    after do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :local
    end

    it "returns time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      expect(%(EST EDT)).to include(Delayed::Job.db_time_now.zone)
    end

    it "returns UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      expect(Delayed::Backend::ActiveRecord::Job.db_time_now.zone).to eq 'UTC'
    end

    it "returns local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      expect(%w(CST CDT)).to include(Delayed::Backend::ActiveRecord::Job.db_time_now.zone)
    end
  end

  describe "after_fork" do
    it "calls reconnect on the connection" do
      ActiveRecord::Base.should_receive(:establish_connection)
      Delayed::Backend::ActiveRecord::Job.after_fork
    end
  end

  describe "enqueue" do
    before :each do
      Delayed::Backend::ActiveRecord::Job.destroy_all
    end

    it "allows enqueue hook to modify job at DB level" do
      later = described_class.db_time_now + 20.minutes
      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
      expect(Delayed::Backend::ActiveRecord::Job.find(job.id).run_at).to be_within(1).of(later)
    end

    it "enqueue job with a generated digest" do
      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
      expect(Delayed::Backend::ActiveRecord::Job.find(job.id).digest).to_not be_blank
    end

    it "not allows enqueue duplicated jobs" do
      obj = EnqueueJobMod.new
      job1 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => obj
      job2 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => obj
      expect(job1).to eq job2
      expect(Delayed::Backend::ActiveRecord::Job.count).to eq 1
    end

    it "allows enqueue non-duplicated jobs" do
      job1 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => SimpleJob.new
      job2 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => NamedJob.new
      expect(job1).to_not eq job2
      expect(Delayed::Backend::ActiveRecord::Job.count).to eq 2
    end

    it "allows enqueue duplicated jobs when the parameter 'allow_duplication' is passed to 'true'" do
      obj = EnqueueJobMod.new
      job1 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => obj
      job2 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => obj, :allow_duplication => true
      expect(job1.id).to_not eq job2.id
      expect(Delayed::Backend::ActiveRecord::Job.count).to eq 2
    end

    it "allows enqueue duplicated jobs when the payload_object has defined the method 'allow_duplication' and it returns 'true'" do
      obj = AllowDuplicationJob.new
      job1 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => obj
      job2 = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => obj
      expect(job1.id).to_not eq job2.id
      expect(Delayed::Backend::ActiveRecord::Job.count).to eq 2
    end
  end

  context "ActiveRecord::Base.send(:attr_accessible, nil)" do
    before do
      Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, nil)
    end

    after do
      Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, *Delayed::Backend::ActiveRecord::Job.new.attributes.keys)
    end

    it "is still accessible" do
      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
      expect(Delayed::Backend::ActiveRecord::Job.find(job.id).handler).to_not be_blank
    end
  end

  context "ActiveRecord::Base.table_name_prefix" do
    it "when prefix is not set, use 'delayed_jobs' as table name" do
      ::ActiveRecord::Base.table_name_prefix = nil
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name

      expect(Delayed::Backend::ActiveRecord::Job.table_name).to eq 'delayed_jobs'
    end

    it "when prefix is set, prepend it before default table name" do
      ::ActiveRecord::Base.table_name_prefix = 'custom_'
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name

      expect(Delayed::Backend::ActiveRecord::Job.table_name).to eq 'custom_delayed_jobs'

      ::ActiveRecord::Base.table_name_prefix = nil
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name
    end
  end
end
