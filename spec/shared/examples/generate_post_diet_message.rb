RSpec.shared_examples 'should generate post diet message' do |message|
  it 'should generate post diet message' do
    group = InviteeGroup.find(invitee_group.id)
    invite_awaiting_diet_index = nil
    group.invites.accepted.each_with_index do |invite, index|
      if invite.awaiting_diet
        invite_awaiting_diet_index = index
        break
      end
    end

    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i }

    intersection = [1,2,3,4] & converted_indexes

    if intersection.any?
      if converted_indexes.include? 4
        message = "Please describe #{group.invitees[invite_awaiting_diet_index].name}’s dietary restrictions."
      else

        low_index = invite_awaiting_diet_index + 1
        high_index = invitee_group.invites.count - 1
        next_person = nil

        if low_index > high_index
          next_person = nil
        elsif low_index == high_index
          if invitee_group.invites[low_index].rsvp_status == 'accepted' && invitee_group.invites[low_index].awaiting_diet == true
            next_person = invitee_group.invites[low_index].invitee.name
          else
            next_person = nil
          end
        else
          remaining_invite_indexes = low_index..high_index
          remaining_invite_indexes.each do |remaining_invite_index|
            if invitee_group.invites[remaining_invite_index].rsvp_status == 'accepted' && invitee_group.invites[remaining_invite_index].awaiting_diet == true
              next_person = invitee_group.invites[remaining_invite_index].invitee.name
              break
            else
              next_person = nil
            end
          end
        end

        if next_person.nil?
          message = "Thanks for all the information. We'll make sure to keep it in mind while planning for the reception dinner. Text VIEW to view a summary of your responses."
        else
          message = "Alright. Next is #{next_person}. Is #{next_person} (1) vegetarian, (2) vegan, (3) under 21/will not drink or (4) other? Plese text the numbers (separated with commas) associated with the statements that apply to #{next_person}."
        end
      end
    else
      message = "Looks like you've sent this computer numbers which aren't associated with any available option. Try again or reach out to the bride or groom for help."
    end

    lead_number = '+1' + invitee_group.leads.first.phone_number

    expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
    subject
  end
end