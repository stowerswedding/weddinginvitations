RSpec.shared_examples 'should mark those with diet' do |message|
  it 'should mark those with diet' do
    subject

    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }
    group = InviteeGroup.find(invitee_group.id)

    bad_marking = true
    converted_indexes.each do |index|
      bad_marking = false if group.invites.accepted[index]
    end

    unless bad_marking
      group.invites.accepted.each_with_index do |invite, index|
        if converted_indexes.include? index
          expect(invite.awaiting_diet).to eq true
        else
          expect(invite.awaiting_diet).to eq false
          expect(invite.invitee.will_drink).to eq true
        end
      end
    end
  end
end