class Invite < ApplicationRecord
  belongs_to :invitee, dependent: :destroy
  belongs_to :invitee_group

  enum role: { member: 0, lead: 1 }
  enum rsvp_status: { pending: 0, accepted: 1, declined: 2 }
end