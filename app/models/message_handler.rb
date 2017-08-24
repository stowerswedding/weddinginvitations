class MessageHandler
  def self.send_pending_invites
    twilio_number = Rails.application.secrets.twilio_number

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

      twilio_client.messages.create(to: invitee_group_phone_number, from: twilio_number, body: message_body)
      invitee_group.update(progress_point: :invitation_sent)
    end
  end

  private

  def self.twilio_client
    account_sid = Rails.application.secrets.twilio_sid
    auth_token = Rails.application.secrets.twilio_token
    Twilio::REST::Client.new account_sid, auth_token
  end
end