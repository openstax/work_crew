require 'rails_helper'

def check_method_calls(called:, uncalled:)
  called.each do |thing|
    if thing.is_a?(Array)
      method_name = thing[0]
      call_count  = thing[1]

      it "calls #{method_name} #{call_count} times" do
        action
        expect(given_world).to have_received(method_name).exactly(call_count).times
      end
    else
      method_name = thing
      it "calls #{method_name}" do
        action
        expect(given_world).to have_received(method_name).once
      end
    end
  end

  uncalled.each do |method_name|
    it "does not call #{method_name}" do
      action
      expect(given_world).to_not have_received(method_name)
    end
  end
end

RSpec.describe 'WorkCrew::Core#process' do
  let(:given_process_time) { Chronic.parse('Oct 6, 2014 14:56:31.5256') }

  let(:core) {
    WorkCrew::Core.new(
      world: given_world
    )
  }

  let(:given_world) {
    dbl = double
    allow(dbl).to receive(:has_group_records?)
              .and_return(has_group_records_return_value)
    allow(dbl).to receive(:read_group_records)
    allow(dbl).to receive(:categorize_records)
    allow(dbl).to receive(:clear_group_records)
    allow(dbl).to receive(:create_instance_record)
    allow(dbl).to receive(:has_instance_record?)
              .and_return(has_instance_record_return_value)
    allow(dbl).to receive(:has_boss_record?)
              .and_return(has_boss_record_return_value)
    allow(dbl).to receive(:update_boss_vote)
    allow(dbl).to receive(:align_with_boss)
    allow(dbl).to receive(:am_boss?)
              .and_return(am_boss_return_value)
    allow(dbl).to receive(:has_next_boss_time?)
              .and_return(has_next_boss_time_return_value)
    allow(dbl).to receive(:has_next_work_time?)
              .and_return(has_next_work_time_return_value)
    allow(dbl).to receive(:has_next_end_time?)
              .and_return(has_next_end_time_return_value)
    allow(dbl).to receive(:has_next_update_time?)
              .and_return(has_next_update_time_return_value)
    allow(dbl).to receive(:is_time_for_update?)
              .and_return(is_time_for_update_return_value)
    allow(dbl).to receive(:clear_next_boss_time)
    allow(dbl).to receive(:destroy_dead_records)
    allow(dbl).to receive(:allocate_modulo)
              .and_return(allocate_modulo_return_value)
    allow(dbl).to receive(:end_block_should_be_called?)
              .and_return(end_block_should_be_called_return_value)
    allow(dbl).to receive(:call_end_block).and_return(end_block_return_value)
    allow(dbl).to receive(:compute_and_set_next_end_time)
    allow(dbl).to receive(:boss_block_should_be_called?)
              .and_return(boss_block_should_be_called_return_value)
    allow(dbl).to receive(:call_boss_block)
    allow(dbl).to receive(:compute_and_set_next_boss_time)
    allow(dbl).to receive(:compute_and_set_next_update_time)
    allow(dbl).to receive(:work_block_should_be_called?)
              .and_return(work_block_should_be_called_return_value)
    allow(dbl).to receive(:call_work_block)
    allow(dbl).to receive(:compute_and_set_next_work_time)
    allow(dbl).to receive(:compute_next_wake_time)
    allow(dbl).to receive(:sleep_until_next_event)
    allow(dbl).to receive(:save_record)
    dbl
  }

  let(:has_instance_record_return_value)         { false }
  let(:has_group_records_return_value)           { false }
  let(:has_boss_record_return_value)             { false }
  let(:has_next_boss_time_return_value)          { false }
  let(:has_next_work_time_return_value)          { false }
  let(:has_next_end_time_return_value)           { false }
  let(:has_next_update_time_return_value)        { false }
  let(:is_time_for_update_return_value)          { false }
  let(:am_boss_return_value)                     { false }
  let(:has_next_boss_time_return_value)          { false }
  let(:allocate_modulo_return_value)             { false }
  let(:end_block_should_be_called_return_value)  { false }
  let(:end_block_return_value)                   { false }
  let(:boss_block_should_be_called_return_value) { false }
  let(:work_block_should_be_called_return_value) { false }

  all_methods = [
    :has_group_records?,
    :read_group_records,
    :categorize_records,
    :clear_group_records,
    :has_instance_record?,
    :create_instance_record,
    :has_boss_record?,
    :update_boss_vote,
    :am_boss?,
    :has_next_boss_time?,
    :has_next_work_time?,
    :has_next_end_time?,
    :has_next_update_time?,
    :is_time_for_update?,
    :compute_and_set_next_boss_time,
    :clear_next_boss_time,
    :destroy_dead_records,
    :allocate_modulo,
    :end_block_should_be_called?,
    :call_end_block,
    :compute_and_set_next_end_time,
    :boss_block_should_be_called?,
    :call_boss_block,
    :compute_and_set_next_boss_time,
    :compute_and_set_next_update_time,
    :work_block_should_be_called?,
    :call_work_block,
    :compute_and_set_next_work_time,
    :compute_next_wake_time,
    :sleep_until_next_event,
    :save_record
  ]

  let(:action) { core.process(process_time: given_process_time) }

  called_methods = [
    :read_group_records,
    :categorize_records,
    :has_instance_record?,
  ]
  uncalled_methods = []

  check_method_calls(called: called_methods, uncalled: uncalled_methods)

  context 'when the target instance record does not exist' do
    let(:has_instance_record_return_value) { false }

    called_methods    = [:create_instance_record, :clear_group_records]
    unchecked_methods = [
      :has_group_records?,
      :read_group_records,
      :categorize_records,
      :has_instance_record?,
    ]
    uncalled_methods  = all_methods - called_methods - unchecked_methods

    check_method_calls(called: called_methods, uncalled: uncalled_methods)
  end

  context 'when the target instance record does exist' do
    let(:has_instance_record_return_value) { true }

    called_methods   = [:has_boss_record?]
    uncalled_methods = []

    check_method_calls(called: called_methods, uncalled: uncalled_methods)

    context 'when there is no boss record' do
      let(:has_boss_record_return_value) { false }

      called_methods = [
        :update_boss_vote,
        :clear_group_records
      ]
      unchecked_methods = [
        :has_group_records?,
        :read_group_records,
        :categorize_records,
        :has_instance_record?,
        :has_boss_record?,
        :save_record,
      ]
      uncalled_methods = all_methods - called_methods - unchecked_methods

      check_method_calls(called: called_methods, uncalled: uncalled_methods)
    end

    context 'when there is a boss record' do
      let(:has_boss_record_return_value) { true }

      called_methods    = [
        :align_with_boss,
        :compute_next_wake_time,
        # :save_record, # masked by mocked `align_with_boss`
        :sleep_until_next_event,
      ]
      uncalled_methods  = []

      check_method_calls(called: called_methods, uncalled: uncalled_methods)

      context 'when this instance is the boss' do
        let(:am_boss_return_value) { true }

        called_methods    = [:destroy_dead_records]
        uncalled_methods  = []

        check_method_calls(called: called_methods, uncalled: uncalled_methods)
      end

      context 'when the instance modulo needs to be allocated' do
        let(:allocate_modulo_return_value) { true }

        called_methods    = [:am_boss?, :clear_group_records, :save_record]
        unchecked_methods = [
          :has_group_records?,
          :read_group_records,
          :categorize_records,
          :has_instance_record?,
          :has_boss_record?,
          :destroy_dead_records,
          :allocate_modulo,
        ]
        uncalled_methods  = all_methods - called_methods - unchecked_methods

        check_method_calls(called: called_methods, uncalled: uncalled_methods)
      end

      context 'when the instance modulo does not need to be allocated' do
        let(:allocate_modulo_return_value) { false }

          called_methods    = [[:am_boss?,2]]
          uncalled_methods  = []

          check_method_calls(called: called_methods, uncalled: uncalled_methods)

        context 'when this instance is the boss' do
          let(:am_boss_return_value) { true }

          called_methods    = [
            :has_next_boss_time?,
            :boss_block_should_be_called?,
          ]
          uncalled_methods  = [:clear_next_boss_time]

          check_method_calls(called: called_methods, uncalled: uncalled_methods)

          context 'when this instance has no next_boss_time' do
            let(:has_next_boss_time_return_value) { false }

            called_methods    = [:compute_and_set_next_boss_time]
            uncalled_methods  = []

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end

          context 'when this instance has a next_boss_time' do
            let(:has_next_boss_time_return_value) { true }

            called_methods   = []
            uncalled_methods = [:compute_and_set_next_boss_time]

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end

          context 'when the boss block should be called' do
            let(:has_next_boss_time_return_value)          { true }
            let(:boss_block_should_be_called_return_value) { true }

            called_methods   = [:call_boss_block, :compute_and_set_next_boss_time]
            uncalled_methods = []

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end

          context 'when the boss block should not be called' do
            let(:has_next_boss_time_return_value)          { true }
            let(:boss_block_should_be_called_return_value) { false }

            called_methods   = []
            uncalled_methods = [:call_boss_block, :compute_and_set_next_boss_time]

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end
        end

        context 'when this instance is not the boss' do
          let(:am_boss_return_value) { false }

          called_methods    = [:clear_next_boss_time]
          uncalled_methods  = [
            :destroy_dead_records,
            :compute_and_set_next_boss_time,
            :boss_block_should_be_called?,
            :call_boss_block,
          ]

          check_method_calls(called: called_methods, uncalled: uncalled_methods)
        end

        context 'when this instance has no next_end_time' do
          let(:has_next_end_time_return_value) { false }

          called_methods    = [:compute_and_set_next_end_time]
          uncalled_methods  = []

          check_method_calls(called: called_methods, uncalled: uncalled_methods)
        end

        context 'when this instance has a next_end_time' do
          let(:has_next_end_time_return_value) { true }

          context 'when the end block should be called' do
            let(:end_block_should_be_called_return_value) { true }

            called_methods    = [
              :call_end_block,
              :compute_and_set_next_end_time,
            ]
            uncalled_methods  = []

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end

          context 'when the end block should not be called' do
            let(:end_block_should_be_called_return_value) { false }

            called_methods    = []
            uncalled_methods  = [
              :call_end_block,
              :compute_and_set_next_end_time,
            ]

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end
        end

        context 'when this instance has no next_end_time' do
          let(:has_next_end_time_return_value) { false }

          called_methods    = [:compute_and_set_next_end_time]
          uncalled_methods  = []

          check_method_calls(called: called_methods, uncalled: uncalled_methods)
        end

        context 'when this instance has a next_work_time' do
          let(:has_next_work_time_return_value) { true }

          context 'when the end block should be called' do
            let(:work_block_should_be_called_return_value) { true }

            called_methods    = [
              :call_work_block,
              :compute_and_set_next_work_time,
            ]
            uncalled_methods  = []

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end

          context 'when the end block should not be called' do
            let(:work_block_should_be_called_return_value) { false }

            called_methods    = []
            uncalled_methods  = [
              :call_work_block,
              :compute_and_set_next_work_time,
            ]

            check_method_calls(called: called_methods, uncalled: uncalled_methods)
          end
        end

      end
    end
  end
end
