RSpec.shared_examples 'progress should not be made' do |current_progress_point|
  it 'progress should not be made' do
    subject

    group = InviteeGroup.find(invitee_group.id)
    progress_point = group.progress_point

    expect(progress_point).to eq current_progress_point
  end
end