class InviteeGroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @invitee_groups = InviteeGroup.all
  end

  def new
    @invitee_group = InviteeGroup.new
  end

  def group_form
  #   respond_to do |format|
  #     format.js {render layout: false}
  #   end
  end

  alias invitee_form group_form

  def create
    @invitee_group = InviteeGroup.create

    lead_name = lead_params['name']
    lead_phone_number = lead_params['phone_number']

    @invitee_group.leads.create name: lead_name, phone_number: lead_phone_number
    @invitee_group.invites = [@invitee_group.leads.first.invite]

    if members_params
      members_params.each do |member_params|
        member_name = members_params[member_params]['name']

        @invitee_group.members.create name: member_name
        @invitee_group.invites << @invitee_group.members.last.invite
      end
    end

    @invitee_group.save

    redirect_to invitee_groups_path
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def lead_params
    params['invitee_group']['lead']
  end

  def members_params
    params['invitee_group']['members']
  end

end