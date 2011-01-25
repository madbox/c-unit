class CreateConfUnits < ActiveRecord::Migration
  def self.up
    create_table :conf_units do |t|
      t.column :parent_id, :integer
      t.column :root_id, :integer
      t.column :name, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :conf_units
  end
end
