class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def reply
    message_body = params['Body']
    from_number = params['From']
    twilio_number = Rails.application.secrets.twilio_number
    reply_body = "Hello there, thanks for texting me. Your number is #{from_number}."
    boot_twilio
    sms = @client.messages.create(from: twilio_number, to: from_number, body: reply_body)
  end

  private

  def boot_twilio
    account_sid = Rails.application.secrets.twilio_sid
    auth_token = Rails.application.secrets.twilio_token
    @client = Twilio::REST::Client.new account_sid, auth_token
  end
end