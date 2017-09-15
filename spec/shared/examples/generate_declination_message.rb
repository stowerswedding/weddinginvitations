RSpec.shared_examples 'should generate declination message' do
  it 'should generate declination message' do
    lead_number = '+1' + invitee_group.leads.first.phone_number
    message = ['Thank you for RSVPing! We hope you’ll keep us in your hearts and celebrate with us from afar.',
               'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
               'Text VIEW to view a summary of your responses.'
    ].join("\n")

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end