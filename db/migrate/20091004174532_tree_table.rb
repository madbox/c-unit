class TreeTable < ActiveRecord::Migration
  def self.up
    create_table :posts_tree, :id => false do |t|
      t.column :owner_id, :integer, :null => false
      t.column :parent_id, :integer, :null => false
      t.column :level, :integer, :default => 0, :null => false
    end

    add_index :posts_tree, [:owner_id, :parent_id], :unique => true
  end

  def self.down
    drop_table :posts_tree
  end
end
