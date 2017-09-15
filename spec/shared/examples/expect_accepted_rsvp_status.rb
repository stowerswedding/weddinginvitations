RSpec.shared_examples 'all invitees accept invitation' do
  it 'should set the rsvp status for all invites to accepted' do
    subject
    invites = InviteeGroup.find(invitee_group.id).invites
    accepted_invites = InviteeGroup.find(invitee_group.id).invites.accepted.count
    expect(accepted_invites).to eq invites.count
  end
end