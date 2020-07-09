class CreateFirmRolesTable < ActiveRecord::Migration[6.0]
  def change
    create_table :firm_roles, id: :uuid do |t|
      t.uuid :firm_id
      t.uuid :role_id
    end
  end
end
