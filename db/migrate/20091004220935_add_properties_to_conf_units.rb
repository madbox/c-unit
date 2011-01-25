class AddPropertiesToConfUnits < ActiveRecord::Migration
  def self.up
    add_column :conf_units, :properties, :text
    add_column :conf_units, :kind, :string, :null => false, :default => 'default'
  end

  def self.down
    remove_column :conf_units, :properties
    remove_column :conf_units, :kind
  end
end
