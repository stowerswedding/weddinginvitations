class Invitee < ApplicationRecord
  has_one :invite
  has_one :invitee_group, through: :invite
end