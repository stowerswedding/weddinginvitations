class CreateInvites < ActiveRecord::Migration[5.1]
  def change
    create_table :invites do |t|
      t.belongs_to :invitee_group, index: true
      t.belongs_to :invitee, index: true
      t.integer :rsvp_status, null: false, default: 0
      t.boolean :awaiting_diet, null: false, default: false
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    create_table :invitee_groups do |t|
      t.integer :progress_point, null: false, default: 0

      t.timestamps
    end

    create_table :invitees do |t|
      t.string :name
      t.string :phone_number
      t.integer :diet, default: nil
      t.string :diet_details
      t.boolean :will_drink

      t.timestamps
    end
  end
end