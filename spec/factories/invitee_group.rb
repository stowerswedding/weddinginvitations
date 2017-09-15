FactoryGirl.define do
  factory :invitee_group do

    after(:create) do |invitee_group|
      invitee_group.leads.create name: 'Anastasia', phone_number: '2107239168'
      invitee_group.invites << invitee_group.leads.first.invite
    end

    trait :second_invitee do
      after(:create) do |invitee_group|
        invitee_group.members.create name: 'Joshua'
        invitee_group.invites << invitee_group.members.last.invite
      end
    end

    trait :third_invitee do
      after(:create) do |invitee_group|
        invitee_group.members.create name: 'Yuki'
        invitee_group.invites << invitee_group.members.last.invite
      end
    end

    trait :invitation_sent do
      after(:create) do |invitee_group|
        invitee_group.update(progress_point: 'invitation_sent')
      end
    end

    trait :rsvp_received do
      after(:create) do |invitee_group|
        invitee_group.update(progress_point: 'rsvp_received')
      end
    end

    trait :awaiting_partial_rsvp do
      after(:create) do |invitee_group|
        invitee_group.update(progress_point: 'awaiting_partial_rsvp')
      end
    end

    trait :diet_flow_initialized do
      after(:create) do |invitee_group|
        invitee_group.update(progress_point: 'diet_flow_initialized')
      end
    end

    trait :awaiting_diet do
      after(:create) do |invitee_group|
        invitee_group.update(progress_point: 'awaiting_diet')
      end
    end

    trait :all_awaiting_diet do
      after(:create) do |invitee_group|
        invitee_group.invites.each do |invite|
          invite.update(awaiting_diet: true)
        end
      end
    end

    trait :partial_awaiting_diet do
      transient do
        awaiting_diet_indexes nil
      end

      after(:create) do |invitee_group, evaluator|
        if evaluator.awaiting_diet_indexes
          indexes = evaluator.awaiting_diet_indexes.map { |i| i - 1 }
          invitee_group.invites.each_with_index do |invite, index|
            invite.update(awaiting_diet: true) if indexes.include? index
          end
        end
      end
    end

    trait :all_accepted do
      after(:create) do |invitee_group|
        invitee_group.invites.each do |invite|
          invite.update(rsvp_status: 'accepted')
        end
      end
    end

    trait :partial_accepted do
      transient do
        rsvp_accepted_indexes nil
      end

      after(:create) do |invitee_group, evaluator|
        if evaluator.rsvp_accepted_indexes
          indexes = evaluator.rsvp_accepted_indexes.map { |i| i - 1 }
          invitee_group.invites.each_with_index do |invite, index|
            if indexes.include? index
              invite.update(rsvp_status: 'accepted')
            else
              invite.update(rsvp_status: 'declined')
            end
          end
        end
      end
    end

    trait :all_declined do
      after(:create) do |invitee_group|
        invitee_group.invites.each do |invite|
          invite.update(rsvp_status: 'declined')
        end
      end
    end

    trait :complete do
      after(:create) do |invitee_group|
        invitee_group.update(progress_point: 'complete')
      end
    end
  end
end