FactoryBot.define do
  factory :work_crew_member_data, class: WorkCrew::MemberData do
    group_uuid      { SecureRandom.uuid.to_s }
    group_desc      { 'some random group' }

    instance_uuid   { SecureRandom.uuid.to_s }
    instance_count  { 1 }
    instance_modulo { 0 }
    instance_desc   { 'some random instance' }

    boss_uuid       { SecureRandom.uuid.to_s }

    next_end_time   { Time.now.utc }
    next_boss_time  { Time.now.utc }
    next_work_time  { Time.now.utc }
  end
end
