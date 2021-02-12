class AddUserCountToOrgs < ActiveRecord::Migration[5.2]
  def change
    add_column :orgs, :users_count, :integer, default: 0
  end
end
