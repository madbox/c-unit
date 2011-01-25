class AddBrokenFlagToConfUnits < ActiveRecord::Migration
  def self.up
    add_column :conf_units, :broken, :boolean, :default => false, :nill => false
  end

  def self.down
    remove_column :conf_units, :broken
  end
end
