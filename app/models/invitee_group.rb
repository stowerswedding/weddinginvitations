class InviteeGroup < ApplicationRecord
  has_many :invites, autosave: true, dependent: :destroy
  has_many :invitees, through: :invites, autosave: true

  has_many :member_invites, -> { where role: :member }, class_name: 'Invite', autosave: true
  has_many :members, through: :member_invites, source: :invitee, autosave: true

  has_many :lead_invites, -> { where role: :lead }, class_name: 'Invite', autosave: true
  has_many :leads, through: :lead_invites, source: :invitee, autosave: true

  accepts_nested_attributes_for :invites
  accepts_nested_attributes_for :invitees

  enum progress_point: {
    invitation_pending: 0,
    invitation_sent: 1,
    rsvp_received: 2,
    awaiting_partial_rsvp: 3,
    diet_flow_initialized: 4,
    awaiting_diet: 5,
    complete: 6
  }

  def lead_invite
    lead_invitees.first
  end
end
