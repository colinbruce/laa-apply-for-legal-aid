class CreateProviderRoles < ActiveRecord::Migration[6.0]
  def change
    create_table :provider_roles, id: :uuid do |t|
      t.uuid :provider_id
      t.uuid :role_id
    end
  end
end
