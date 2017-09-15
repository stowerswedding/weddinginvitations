RSpec.shared_examples 'should reset all' do
  it 'should reset all' do
    subject
    invitee_group.invites.each do |invite|
      expect(invite.rsvp_status).to eq 'pending'
      expect(invite.invitee.diet).to eq nil
      expect(invite.invitee.diet_details).to eq nil
      expect(invite.invitee.will_drink).to eq nil
    end
  end
end