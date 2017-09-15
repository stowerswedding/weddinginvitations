RSpec.shared_examples 'should send summary message' do
  it 'should send summary message' do
    lead_number = '+1' + invitee_group.leads.first.phone_number
    def get_summary_string(invite)
      if invite.rsvp_status == 'accepted'
        "#{invite.invitee.name} - #{invite.rsvp_status} invitation - diet: #{invite.invitee.diet}#{' - extra details: ' if invite.invitee.diet && invite.invitee.diet_details}#{invite.invitee.diet_details} - #{invite.invitee.will_drink ? 'will drink': 'will not drink'}"
      else
        "#{invite.invitee.name} - #{invite.rsvp_status} invitation"
      end
    end

    message = [ 'Received responses:' ]
    if invitee_group.invites.many?
      invitee_group.invites.each do |invite|
        message << get_summary_string(invite)
      end
    else
      message << get_summary_string(invitee_group.invites.first)
    end
    message << 'Text EDIT to start over and change your responses.'
    message = message.join("\n")

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end