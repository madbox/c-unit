ActiveRecord::Schema.define :version => 0 do
  create_table :posts, :force => true do |t|
    t.column :parent_id,    :integer
    t.column :root_id,      :integer
    t.column :name,         :string
  end

  create_table :posts_tree, :force => true, :id => false do |t|
    t.column :owner_id,     :integer, :null => false
    t.column :parent_id,    :integer, :null => false
    t.column :level,        :integer, :default => 0, :null => false
  end
  add_index :posts_tree, [:owner_id, :parent_id], :unique => true
end
