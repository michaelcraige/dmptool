class DropTableFriendlyIdSlugs < ActiveRecord::Migration[4.2]
  def up
    drop_table :friendly_id_slugs if table_exists?(:friendly_id_slugs)
  end

  def down
    create_table :friendly_id_slugs do |t|
      t.string   :slug,           :null => false
      t.integer  :sluggable_id,   :null => false
      t.string   :sluggable_type, :limit => 40
      t.datetime :created_at
    end
    add_index :friendly_id_slugs, :sluggable_id
    add_index :friendly_id_slugs, [:slug, :sluggable_type], :unique => true
    add_index :friendly_id_slugs, :sluggable_type
  end
end
