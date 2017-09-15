RSpec.shared_examples 'should generate conclusion message' do
  it 'should generate conclusion message' do
    lead_number = '+1' + invitee_group.leads.first.phone_number
    message = ['Thanks for letting us know.',
               'Text VIEW to view a summary of your responses.',
    ].join("\n")

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end