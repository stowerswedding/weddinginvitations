RSpec.shared_examples 'should send generic error message' do
  it 'should send generic error message' do
    lead_number = '+1' + invitee_group.leads.first.phone_number
    message = "Sorry. Our silly computer didn't understand your response. Try again or reach out to the bride or groom for help."

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end