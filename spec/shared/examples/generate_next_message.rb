RSpec.shared_examples 'should generate next message instructions' do
  it 'should generate next message instructions' do
    lead_number = '+1' + invitee_group.leads.first.phone_number
    message = [ 'Alright, here are the people in your party:' ]
    invitee_group.invitees.each_with_index do |invitee, index|
      message << "(#{index+1}) #{invitee.name}"
    end
    message << 'Please text the numbers associated with the individuals who CAN attend, separated with commas.'
    message = message.join("\n")

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end