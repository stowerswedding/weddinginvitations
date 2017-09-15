RSpec.shared_examples 'should send reset message' do
  it 'should send reset message' do
    lead_number = '+1' + invitee_group.leads.first.phone_number
    if invitee_group.invitees.many?
      message = "Okay. We'll start over. Please text YES if everyone in your party can come, NO if you are all unable, or PART if only part of your party can make it."
    else
      message = "Okay. We'll start over. Please text YES if you can come or NO if you are unable."
    end

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end