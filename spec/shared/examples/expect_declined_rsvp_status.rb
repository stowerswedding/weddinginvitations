RSpec.shared_examples 'all invitees decline invitation' do
  it 'should set the rsvp status for all invites to declined' do
    subject
    invites = InviteeGroup.find(invitee_group.id).invites
    declined_invites = InviteeGroup.find(invitee_group.id).invites.declined.count
    expect(declined_invites).to eq invites.count
  end
end