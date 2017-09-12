class MessageHandler

  def self.send_pending_invites
    invitee_groups = InviteeGroup.invitation_pending
    invitee_groups.each do |invitee_group|
      invitee_group_phone_number = invitee_group.leads.first['phone_number']
      invitee_list = ''
      has_party_string = invitee_group.invitees.many? ? ' If only part of your party can come text PART.' : ''

      invitee_group.invitees.each_with_index do |invitee, index|
        if index.zero?
          invitee_list += invitee.name
        elsif index == invitee_group.invitees.count - 1
          if invitee_group.invitees.count == 2
            invitee_list += ' and ' + invitee.name
          else
            invitee_list += ', and ' + invitee.name
          end
        else
          invitee_list += ', ' + invitee.name
        end
      end

      message_body = [
          "Save the Date!\n",
          "Joshua Stowers and Anastasia Krisan are excited to invite #{invitee_list} to our wedding. ",
          "3pm on January 14th, 2018 at Our Lady of Grace: 223 East Summit San Antonio, Texas 78212  ",
          "Dinner and dancing to follow at Magnolia Gardens on Main: 2030 N Main Ave San Antonio, TX 78212\n",
          "Please text YES if you are saving the date and can join us or text NO if sadly, you won’t be able to be with us.#{has_party_string}\n",
          "See more details on the event and our wedding registry at: http://wedding.stowers.info"
      ].join("\n")

      send_message(invitee_group_phone_number, message_body)

      invitee_group.update(progress_point: :invitation_sent)
    end
  end

  def self.receive_message(phone_number, message)
    lead_invitee = Invitee.find_by(phone_number: phone_number.sub('+1', ''))
    return unless lead_invitee.present?

    invite = Invite.find_by(invitee: lead_invitee)

    if invite.rsvp_status == 'pending' && invite.invitee_group.invitation_sent?
      reply_body = process_rsvp(invite.invitee_group, message)
    elsif invite.invitee_group.awaiting_partial_rsvp?
      reply_body = process_partial_rsvp(invite.invitee_group, message)
    elsif invite.invitee_group.rsvp_received?
      reply_body = initialize_diet_flow(invite.invitee_group, message)
    elsif invite.invitee_group.diet_flow_initialized?
      reply_body = mark_those_with_diet(invite.invitee_group, message)
    elsif invite.invitee_group.awaiting_diet?
      reply_body = process_diet(invite.invitee_group, message)
    end

    raise reply_body

    send_message(phone_number, reply_body)
  end

  private

  def self.twilio_client
    account_sid = Rails.application.secrets.twilio_sid
    auth_token = Rails.application.secrets.twilio_token
    Twilio::REST::Client.new account_sid, auth_token
  end

  def self.send_message (phone_number, message)
    twilio_number = Rails.application.secrets.twilio_number
    twilio_client.messages.create(to: phone_number, from: twilio_number, body: message)
  end

  def self.parse_numbers(message)
    message.scan /(?<!\d)\d+/
  end

  def self.process_rsvp(invitee_group, message)
    "Sorry. Our silly computer didn't understand your response. Try again or reach out to the bride or groom for help."

    if message == 'YES'

      save_rsvp(invitee_group, 'accepted')
      invitee_group.update(progress_point: :rsvp_received)
      generate_acceptance_message

    elsif message == 'NO'

      save_rsvp(invitee_group, 'declined')
      invitee_group.update(progress_point: :complete)
      generate_declination_message

    elsif message == 'PART' && invitee_group.invitees.many?

      await_response(invitee_group)
      generate_next_instructions_message(invitee_group)

    end

  end

  def self.process_partial_rsvp(invitee_group, message)

    save_partial_rsvps(invitee_group, message)
    accepted_invitees_list = generate_accepted_invitees_list(invitee_group)
    generate_partial_acceptance_message(accepted_invitees_list)

  end

  def self.initialize_diet_flow(invitee_group, message)
    "Sorry. Our silly computer didn't understand your response. Try again or reach out to the bride or groom for help."

    if message == 'YES'

      set_progress_point(invitee_group, 'diet_flow_initialized')
      generate_party_list_message(invitee_group)

    elsif message == 'NO'

      set_progress_point(invitee_group, 'complete')
      generate_conclusion_message

    end

  end

  def self.process_diet(invitee_group, message)
    current_invite = get_current_invite(invitee_group)

    if is_number?(message)
      delivered_indexes = parse_numbers(message)

      set_diet(current_invite, delivered_indexes)

      if delivered_indexes.include? '4'
        "Please describe #{current_invite.invitee.name}’s dietary restrictions."
      else
        current_invite.update(awaiting_diet: false)
        get_post_diet_reply(invitee_group)
      end
    else
      reply = get_post_diet_reply(invitee_group)
      current_invite.invitee.update(diet: message)
      current_invite.update(awaiting_diet: false)
      reply
    end
  end

  def self.get_post_diet_reply(invitee_group)
    next_person = get_next_invitee(invitee_group)
    if next_person.nil?
      invitee_group.update(progress_point: :complete)
      "Thanks for all the information. We'll make sure to keep it in mind while planning for the reception dinner. If you need to make changes to your responses, text EDIT."
    else
      "Alright. Next is #{next_person}. Is #{next_person} (1) vegetarian, (2) vegan, (3) under 21 or (4) other? Plese text the numbers (separated with commas) associated with the statements that apply to #{next_person}."
    end
  end

  def self.is_number? string
    re = /[^\d.,]/
    string.gsub(' ', '') !~ re
  end

  def self.save_rsvp(invitee_group, rsvp)
    invitee_group.invitees.each do |invitee|
      invitee.invite.update(rsvp_status: rsvp)
    end
  end

  def self.generate_acceptance_message
    ['Thank you for RSVPing! We can’t wait to celebrate with you.',
     'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
     'Is there anyone in your party that has diet restrictions or is under the age of 21? Please text YES or NO.'
    ].join("\n")
  end

  def self.generate_declination_message
    ['Thank you for RSVPing! We hope you’ll keep us in your hearts and celebrate with us from afar.',
     'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
     'If you need to make changes to your responses, text EDIT.'
    ].join("\n")
  end

  def self.await_response(invitee_group)
    invitee_group.update(progress_point: :awaiting_partial_rsvp)
  end

  def self.generate_next_instructions_message(invitee_group)
    reply_body = [ 'Alright, here are the people in your party:' ]
    invitee_group.invitees.each_with_index do |invitee, index|
      reply_body << "(#{index+1}) #{invitee.name}"
    end
    reply_body << 'Please text the numbers associated with the individuals who CAN attend, separated with commas.'
    reply_body = reply_body.join("\n")
  end

  def self.save_partial_rsvps(invitee_group, message)
    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }

    invitee_group.invitees.each_with_index do |invitee, index|
      if converted_indexes.include? index
        invitee.invite.update(rsvp_status: 'accepted')
      else
        invitee.invite.update(rsvp_status: 'declined')
      end
    end

    invitee_group.update(progress_point: :rsvp_received)
  end

  def self.generate_accepted_invitees_list(invitee_group)
    accepted_invitees_list = []
    invitee_group.invitees.each_with_index do |invitee, index|
      if converted_indexes.include? index
        accepted_invitees_list << invitee.name
      end
    end
    accepted_invitees_list
  end

  def self.generate_partial_acceptance_message(accepted_invitees_list)
    ["Thank you for RSVPing. We’re glad to hear that #{accepted_invitees_list.to_sentence} can come. We can’t wait to celebrate with you.",
     'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
     'Is there anyone in your party that has diet restrictions or is under the age of 21? Please text YES or NO.'
    ].join("\n")
  end

  def self.set_progress_point(invitee_group, progress_point)
    invitee_group.update(progress_point: progress_point.to_sym)
  end

  def self.generate_party_list_message(invitee_group)
    if invitee_group.invites.accepted.count > 1
      reply_body = [ 'Alright, here are the people in your party:' ]
      invitee_group.invitees.each_with_index do |invitee, index|
        if invitee.invite.rsvp_status == 'accepted'
          reply_body << "(#{index+1}) #{invitee.name}"
        end
      end
      reply_body << 'Please text the numbers (separated with commas) associated with the individuals who have dietary restrictions or who are under the age of 21.'
      reply_body.join("\n")
    else
      if invitee_group.invitees.many?
        reply_body = [
            'Here are the options:',
            "(1) #{invitee_group.invitees.accepted.first.name} has dietary restrictions.",
            "(2) #{invitee_group.invitees.accepted.first.name} is under the age of 21.",
            "Please text the numbers (separated with commas) associated with the statements which apply to #{invitee_group.invitees.accepted.first.name}."
        ]
      else
        reply_body = [
            'Here are the options:',
            '(1) I have dietary restrictions.',
            '(2) I am under the age of 21.',
            'Please text the numbers (separated with commas) associated with the statements which apply to you.'
        ]
      end
      reply_body.join("\n")
    end
  end

  def self.generate_conclusion_message
    ['Thanks for letting us know.',
     'If you need to make changes to your responses, text EDIT.',
    ].join("\n")
  end

  def self.mark_those_with_diet(invitee_group, message)
    delivered_indexes = message.scan /(?<!\d)\d+/
    converted_indexes = delivered_indexes.map { |i| i.to_i - 1 }
    dietary_restricted_invitees_list = []

    current_index = 0
    invitee_group.invitees.each do |invitee|
      next unless invitee.invite.rsvp_status == 'accepted'
      if converted_indexes.include? current_index
        dietary_restricted_invitees_list << invitee.name
        invitee.invite.update(awaiting_diet: true)
      else
        invitee.invite.update(awaiting_diet: false)
        invitee.update(will_drink: true)
      end
      current_index += 1
    end

    set_progress_point(invitee_group, 'awaiting_diet')

    "Okay, so #{dietary_restricted_invitees_list.to_sentence} #{'has'.pluralize(dietary_restricted_invitees_list.count)} dietary restrictions.#{ "Let’s start with " + dietary_restricted_invitees_list.first + ". " if dietary_restricted_invitees_list.many?} Is #{dietary_restricted_invitees_list.first} (1) vegetarian, (2) vegan, (3) under 21 or (4) other? Plese text the numbers (separated with commas) associated with the statements that apply to #{dietary_restricted_invitees_list.first}."

  end

  def self.invite_awaiting_diet(invite)
    invite.rsvp_status == 'accepted' && invite.awaiting_diet? ? true : false
  end

  def self.get_current_invite(invitee_group)
    if invitee_group.invites.many?
      invitee_group.invites.select { |invite| invite_awaiting_diet(invite) }.first
    else
      invitee_group.invites.first
    end
  end

  def self.get_current_invite_index(invitee_group)
    return nil unless invitee_group.invites.many?
    invitee_group.invites.each_with_index do |invite, index|
      return index if invite_awaiting_diet(invite)
    end
    return nil
  end

  def self.get_next_invitee(invitee_group)
    index = get_current_invite_index(invitee_group)

    return nil if index.nil?

    low_index = index + 1
    high_index = invitee_group.invites.count - 1

    return nil if low_index >= high_index

    remaining_invite_indexes = low_index..high_index
    remaining_invite_indexes.each do |remaining_invite_index|
      if invite_awaiting_diet(invitee_group.invites[remaining_invite_index])
        return invitee_group.invites[remaining_invite_index].invitee.name
      end
    end
  end

  def self.set_diet(invite, indexes)
    if indexes.many?
      indexes.each do |index|
        match_diet(invite, index)
      end
    else
      match_diet(invite, indexes)
    end
  end

  def self.match_diet(invite, num)
    case num
    when '1' then invite.invitee.update(diet: 'vegetarian')
    when '2' then invite.invitee.update(diet: 'vegan')
    when '3' then invite.invitee.update(will_drink: false)
    end
  end

end