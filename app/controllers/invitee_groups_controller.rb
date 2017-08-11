class InviteeGroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @invitee_groups = InviteeGroup.all
  end

  def new
    @invitee_group = InviteeGroup.new
    @invitees = @invitee_group.invitees.build
    @invites = @invitee_group.invites.build
  end

  def group_form
  #   respond_to do |format|
  #     format.js {render layout: false}
  #   end
  end

  alias invitee_form group_form

  def create
    @invitee_group = InviteeGroup.create

    invitee_name = invitees_attributes_params['name']
    invitee_phone_number = invitees_attributes_params['phone_number']

    @invitee_group.leads.create name: invitee_name, phone_number: invitee_phone_number
    @invitee_group.invites = [@invitee_group.leads.first.invite]
    @invitee_group.save

    redirect_to invitee_groups_path
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def invitees_attributes_params
    params['invitee_group']['invitees_attributes']['0']
  end

end