class InviteesController < ApplicationController

  skip_before_action :verify_authenticity_token

  def receive_message
    message_body = params['Body'].squish
    from_number = params['From']

    MessageHandler.receive_message(from_number, message_body)
  end

end