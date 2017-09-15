RSpec.shared_examples 'should send partial acceptance message' do |message|
  it 'should send partial acceptance message' do
    lead_number = '+1' + invitee_group.leads.first.phone_number

    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }
    group = InviteeGroup.find(invitee_group.id)

    bad_marking = true
    converted_indexes.each do |index|
      bad_marking = false if group.invites[index]
    end

    if bad_marking
      message = "Looks like you've sent this computer numbers which aren't associated with any party member. Try again or reach out to the bride or groom for help."
    else
      accepted_invitees_list = []
      converted_indexes.each do |index|
        unless index >= group.invitees.count
          accepted_invitees_list << group.invitees[index.to_i].name
        end
      end
      message = ["Thank you for RSVPing. We’re glad to hear that #{accepted_invitees_list.to_sentence} can come. We can’t wait to celebrate with you.",
                 'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
                 'Is there anyone in your party that has diet restrictions or is under the age of 21/will not drink? Please text YES or NO.'
                ].join("\n")
    end

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end