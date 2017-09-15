RSpec.shared_examples 'should set every accepted invitee to will_drink' do
  it 'should set every accepted invitee to will_drink' do
    subject
    invites = InviteeGroup.find(invitee_group.id).invites
    all_will_drink = true
    declined_no_response = true
    invites.accepted.each do |invite|
      unless invite.invitee.will_drink
        all_will_drink = false
      end
    end
    invites.declined.each do |invite|
      unless invite.invitee.will_drink == nil
        declined_no_response = false
      end
    end
    expect(all_will_drink).to eq true
    expect(declined_no_response).to eq true
  end
end