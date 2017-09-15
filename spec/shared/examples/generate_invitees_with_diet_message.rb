RSpec.shared_examples 'should send message with invitees with diet' do |message|
  it 'should send message with invitees with diet' do
    lead_number = '+1' + invitee_group.leads.first.phone_number

    dietary_restricted_invitees_list = []
    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }
    group = InviteeGroup.find(invitee_group.id)

    bad_marking = true
    converted_indexes.each do |index|
      bad_marking = false if group.invites.accepted[index]
    end

    if bad_marking
      message = "Looks like you've sent this computer numbers which aren't associated with any party member. Try again or reach out to the bride or groom for help."
    else
      group.invites.accepted.each_with_index do |invite, index|
        if converted_indexes.include? index
          dietary_restricted_invitees_list << invite.invitee.name
        end
      end

      message = "Okay, so #{dietary_restricted_invitees_list.to_sentence} #{'has'.pluralize(dietary_restricted_invitees_list.count)} dietary restrictions.#{ " Let’s start with " + dietary_restricted_invitees_list.first + "." if dietary_restricted_invitees_list.many?} Is #{dietary_restricted_invitees_list.first} (1) vegetarian, (2) vegan, (3) under 21/will not drink or (4) other? Plese text the numbers (separated with commas) associated with the statements that apply to #{dietary_restricted_invitees_list.first}."
    end

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end