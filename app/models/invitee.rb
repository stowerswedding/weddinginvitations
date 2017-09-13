class Invitee < ApplicationRecord
  has_one :invite
  has_one :invitee_group, through: :invite

  enum diet: { vegetarian: 0, vegan: 1 }
end