RSpec.shared_examples 'should set diet to' do |message|
  it 'should set diet to ' + message do
    group = InviteeGroup.find(invitee_group.id)
    invite_awaiting_diet_index = nil
    group.invites.accepted.each_with_index do |invite, index|
      if invite.awaiting_diet
        invite_awaiting_diet_index = index
        break
      end
    end
    subject

    def is_number? string
      re = /[^\d.,]/
      string.gsub(' ', '') !~ re
    end

    if is_number?(message)
      delivered_indexes = message.scan /(?<!\d)\d+/
      converted_indexes = delivered_indexes.map { |i| i.to_i }

      intersection = [1,2,3,4] & converted_indexes
      if intersection.any?
        converted_indexes.each do |index|
          case index
            when 1
              if converted_indexes.include? 2
                expect(group.invites[invite_awaiting_diet_index].invitee.diet).to eq 'vegan'
              else
                expect(group.invites[invite_awaiting_diet_index].invitee.diet).to eq 'vegetarian'
              end
            when 2 then expect(group.invites[invite_awaiting_diet_index].invitee.diet).to eq 'vegan'
            when 3 then expect(group.invites[invite_awaiting_diet_index].invitee.will_drink).to eq false
          end
        end

        expect(group.invites[invite_awaiting_diet_index].invitee.diet_details).to eq nil
        expect(group.invites[invite_awaiting_diet_index].invitee.will_drink).to eq true unless converted_indexes.include? 3
      end
    else
      expect(group.invites[invite_awaiting_diet_index].invitee.diet_details).to eq message
    end
  end
end