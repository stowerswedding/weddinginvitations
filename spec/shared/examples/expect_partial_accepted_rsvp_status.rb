RSpec.shared_examples 'part of the invitees accept invitation' do |message|
  it 'part of the invitees accept invitation' do
    subject

    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }
    group = InviteeGroup.find(invitee_group.id)

    bad_marking = true
    converted_indexes.each do |index|
      bad_marking = false if group.invites[index]
    end

    unless bad_marking
      partial_accepted = true
      partial_declined = true

      group.invites.each_with_index do |invite, index|
        if converted_indexes.include? index
          partial_accepted = false unless invite.rsvp_status == 'accepted'
        else
          partial_declined = false unless invite.rsvp_status == 'declined'
        end
      end
      expect(partial_accepted).to eq true
      expect(partial_declined).to eq true
    end
  end
end