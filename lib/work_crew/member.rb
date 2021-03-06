module WorkCrew
  class Member
    def initialize(min_end_interval:    nil,
                   end_block:           nil,
                   min_boss_interval:   nil,
                   boss_block:          nil,
                   min_work_interval:   nil,
                   work_block:          nil,
                   min_update_interval: nil,
                   group_uuid:,
                   group_desc:,
                   instance_uuid:,
                   instance_desc:,
                   dead_record_timeout:,
                   dead_record_block: nil,
                   reference_time:,
                   timing_modulo:,
                   timing_offset:)
      @very_long_time = 600.seconds

      @min_end_interval    = min_end_interval || @very_long_time
      @end_block           = end_block
      @min_boss_interval   = min_boss_interval || @very_long_time
      @boss_block          = boss_block
      @min_work_interval   = min_work_interval || @very_long_time
      @work_block          = work_block
      @min_update_interval = min_update_interval || [1.seconds, dead_record_timeout / 3.14159].min

      @group_uuid          = group_uuid
      @group_desc          = group_desc
      @instance_uuid       = instance_uuid
      @instance_desc       = instance_desc
      @dead_record_timeout = dead_record_timeout
      @dead_record_block   = dead_record_block
      @reference_time      = reference_time
      @timing_modulo       = timing_modulo
      @timing_offset       = timing_offset

      @next_wake_time = nil

      @core = WorkCrew::Core.new(world: self)
    end

    def run
      begin
        loop do
          break unless @core.process(process_time: Time.now.utc)
        end
      rescue Interrupt => ex
        # puts 'exiting'
      rescue Exception => ex
        raise ex
      ensure
        destroy_record
      end
    end

    def group_uuid
      @group_uuid
    end

    def group_desc
      @group_desc
    end

    def instance_uuid
      @instance_uuid
    end

    def instance_desc
      @instance_desc
    end

    def am_boss?
      !!@am_boss
    end

    def count
      @instance_record.instance_count
    end

    def modulo
      @instance_record.instance_modulo
    end

    def has_group_records?
      !(@group_records.nil? || @group_records.none?)
    end

    def clear_group_records
      @group_records = []
    end

    def read_group_records
      @group_records = WorkCrew::Helpers.read_group_records(group_uuid: @group_uuid)
    end

    def categorize_records
      @instance_record, @live_records, @dead_records = WorkCrew::Helpers.categorize_records(
        instance_uuid:       @instance_uuid,
        dead_record_timeout: @dead_record_timeout,
        group_records:       @group_records,
      )
    end

    def has_instance_record?
      !!@instance_record
    end

    def create_instance_record
      WorkCrew::Helpers.create_record(
        group_uuid:    @group_uuid,
        group_desc:    @group_desc,
        instance_uuid: @instance_uuid,
        instance_desc: @instance_desc,
      )
    end

    def has_boss_record?
      @am_boss, @boss_record = WorkCrew::Helpers.get_boss_situation(
        instance_uuid: @instance_uuid,
        live_records:  @live_records,
      )
      !!@boss_record
    end

    def align_with_boss
      result = @instance_record.boss_uuid != @boss_record.instance_uuid
      @instance_record.boss_uuid = @boss_record.instance_uuid
      return result
    end

    def update_boss_vote
      WorkCrew::Helpers.update_boss_vote(
        instance_record: @instance_record,
        live_records:    @live_records,
      )
    end

    def allocate_modulo
      WorkCrew::Helpers.allocate_modulo(
        instance_record: @instance_record,
        live_records:    @live_records,
        boss_record:     @boss_record,
      )
    end

    def am_boss?
      !!@am_boss
    end

    def has_next_boss_time?
      return !@instance_record.next_boss_time.nil?
    end

    def has_next_end_time?
      return !@instance_record.next_end_time.nil?
    end

    def has_next_work_time?
      return !@instance_record.next_work_time.nil?
    end

    def has_next_update_time?
      return !@instance_record.next_update_time.nil?
    end

    def clear_next_boss_time
      @instance_record.next_boss_time = nil
    end

    def compute_and_set_next_boss_time(current_time:)
      time_to_use =
        if @instance_record.next_boss_time.nil?
          current_time
        else
          @instance_record.next_boss_time + 1e-5.seconds
        end

      @instance_record.next_boss_time = WorkCrew::Helpers.compute_next_time(
        current_time:    time_to_use,
        reference_time:  @reference_time,
        timing_modulo:   @timing_modulo,
        timing_offset:   @timing_offset,
        instance_count:  @instance_record.instance_count,
        instance_modulo: 0, ## boss time is independent of instance modulo
        interval:        @min_boss_interval
      )

      if @instance_record.next_boss_time < current_time
        @instance_record.next_boss_time = current_time
      end
    end

    def compute_and_set_next_work_time(current_time:)
      time_to_use =
        if @instance_record.next_work_time.nil?
          current_time
        else
          @instance_record.next_work_time + 1e-5.seconds
        end

      @instance_record.next_work_time = WorkCrew::Helpers.compute_next_time(
        current_time:    time_to_use,
        reference_time:  @reference_time,
        timing_modulo:   @timing_modulo,
        timing_offset:   @timing_offset,
        instance_count:  @instance_record.instance_count,
        instance_modulo: @instance_record.instance_modulo,
        interval:        @min_work_interval
      )

      if @instance_record.next_work_time < current_time
        @instance_record.next_work_time = current_time
      end
    end

    def compute_and_set_next_end_time(current_time:)
      time_to_use =
        if @instance_record.next_end_time.nil?
          current_time
        else
          @instance_record.next_end_time + 1e-5.seconds
        end

      @instance_record.next_end_time = WorkCrew::Helpers.compute_next_time(
        current_time:    time_to_use,
        reference_time:  @reference_time,
        timing_modulo:   @timing_modulo,
        timing_offset:   @timing_offset,
        instance_count:  @instance_record.instance_count,
        instance_modulo: @instance_record.instance_modulo,
        interval:        @min_end_interval
      )

      if @instance_record.next_end_time < current_time
        @instance_record.next_end_time = current_time
      end
    end

    def compute_and_set_next_update_time(current_time:)
      time_to_use =
        if @instance_record.next_update_time.nil?
          current_time
        else
          @instance_record.next_update_time + 1e-5.seconds
        end

      @instance_record.next_update_time = WorkCrew::Helpers.compute_next_time(
        current_time:    time_to_use,
        reference_time:  @reference_time,
        timing_modulo:   @timing_modulo,
        timing_offset:   @timing_offset,
        instance_count:  @instance_record.instance_count,
        instance_modulo: @instance_record.instance_modulo,
        interval:        @min_update_interval
      )

      if @instance_record.next_update_time < current_time
        @instance_record.next_update_time = current_time
      end
    end

    def destroy_dead_records
      WorkCrew::Helpers.destroy_dead_records(
        work_crew_member:          self,
        dead_records:      @dead_records,
        dead_record_block: @dead_record_block,
      )
    end

    def boss_block_should_be_called?(current_time:)
      return false if @min_boss_interval.nil? || @instance_record.next_boss_time.nil?
      return current_time > @instance_record.next_boss_time
    end

    def call_boss_block
      @boss_block.call(work_crew_member: self) unless @boss_block.nil?
    end

    def work_block_should_be_called?(current_time:)
      return false if @min_work_interval.nil? || @instance_record.next_work_time.nil?
      return current_time > @instance_record.next_work_time
    end

    def call_work_block
      @work_block.call(work_crew_member: self) unless @work_block.nil?
    end

    def end_block_should_be_called?(current_time:)
      return false if @min_end_interval.nil? || @instance_record.next_end_time.nil?
      return current_time > @instance_record.next_end_time
    end

    def call_end_block
      @end_block.call(work_crew_member: self) unless @end_block.nil?
    end

    def is_time_for_update?(current_time:)
      return false if @min_update_interval.nil? || @instance_record.next_update_time.nil?
      return current_time > @instance_record.next_update_time
    end

    def save_record
      @instance_record.instance_count = @live_records.count
      WorkCrew::Helpers.save_record(record: @instance_record)
    end

    def compute_next_wake_time(current_time:)
      @next_wake_time = [
        @instance_record.next_end_time,
        @instance_record.next_boss_time,
        @instance_record.next_work_time,
        @instance_record.next_update_time,
      ].compact.min
    end

    def sleep_until_next_event
      delay = [@next_wake_time - Time.now, 0.001].max
      # puts "delay = #{delay}"
      sleep(delay)
    end

    def destroy_record
      instance_record = ActiveRecord::Base.connection_pool.with_connection do
        WorkCrew::MemberData.where(instance_uuid: @instance_uuid).take
      end
      instance_record.destroy! if instance_record
    end
  end
end
