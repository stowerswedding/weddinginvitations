RSpec.shared_examples 'progress point should be set to' do |desired_progress_point, message: nil, must_be_accepted_invite: true|
  it 'should set :progress_point to the given progress_point' do
    subject

    group = InviteeGroup.find(invitee_group.id)

    if message
      delivered_indexes = message.scan /(?<!\d)\d+/
      converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }

      bad_marking = true
      converted_indexes.each do |index|
        if must_be_accepted_invite
          bad_marking = false if group.invites.accepted[index]
        else
          bad_marking = false if group.invites[index]
        end
      end

      unless bad_marking
        progress_point = group.progress_point
        expect(progress_point).to eq desired_progress_point
      end
    else
      progress_point = group.progress_point
      expect(progress_point).to eq desired_progress_point
    end
  end
end