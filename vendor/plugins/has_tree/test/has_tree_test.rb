require File.dirname(__FILE__) + '/test_helper'

class Post < ActiveRecord::Base
  has_tree :order => 'name'
end

class HasTreeTest < ActiveSupport::TestCase

  test "create post" do
    assert post("created")
  end

  test "create children post" do
    root = post("root")
    assert root
    child = root.children.create!(:name => "child")
    assert child
    assert_equal root, child.parent
    assert_equal 1, root.children.size
  end

  test "destroy dependent children posts" do
    root = post("root")
    assert root
    child = root.children.create!(:name => "child")
    assert child
    root.destroy
    assert_raise ActiveRecord::RecordNotFound do
      child.reload
    end
  end

  #####

  test ".roots" do
    clear_all
    a = post("a")
    b = post("b")
    a_a = a.children.create!(:name => "a_a")
    b_a = a.children.create!(:name => "b_a")

    assert_equal [a,b], Post.roots
  end

  test ".root" do
    clear_all
    a = post("a")
    b = post("b")
    a_a = a.children.create!(:name => "a_a")
    b_a = a.children.create!(:name => "b_a")

    assert_equal a, Post.root
  end

  test "#root" do
    clear_all
    a = post("a")
    a_a = a.children.create!(:name => "a_a")
    a_a_a = a_a.children.create!(:name => "a_a_a")
    b = post("b")
    b_a = b.children.create!(:name => "b_a")
    b_a_a = b_a.children.create!(:name => "b_a_a")

    assert_equal a, a.root
    assert_equal a, a_a.root
    assert_equal a, a_a_a.root

    assert_equal b, b.root
    assert_equal b, b_a.root
    assert_equal b, b_a_a.root
  end


  test "#self_and_siblings" do
    clear_all
    root = post("root")
    assert root
    child1 = root.children.create!(:name => "child1")
    assert child1
    child2 = root.children.create!(:name => "child2")
    assert child2
    assert_equal [child1, child2], child1.self_and_siblings
  end

  test "#self_and_siblings for root" do
    clear_all
    root1 = post("root1")
    assert root1
    root2 = post("root2")
    assert root2
    assert_equal [root1, root2], root1.self_and_siblings
  end

  test "#siblings" do
    clear_all
    root = post("root")
    assert root
    child1 = root.children.create!(:name => "child1")
    assert child1
    child2 = root.children.create!(:name => "child2")
    assert child2
    assert_equal [child2], child1.siblings
  end

  test "#recursive_ancestors" do
    clear_all
    root = post("root")
    child1 = root.children.create!(:name => "child1")
    child2 = root.children.create!(:name => "child2")
    child11 = child1.children.create!(:name => "child11")
    child12 = child1.children.create!(:name => "child12")
    child121 = child12.children.create!(:name => "child121")

    assert_equal [child12, child1, root], child121.recursive_ancestors
  end

  test "#ancestors" do
    clear_all
    root = post("root")
    a = root.children.create!(:name => "a")
    b = root.children.create!(:name => "b")
    a_a = a.children.create!(:name => "a_a")
    a_b = a.children.create!(:name => "a_b")
    a_b_a = a_b.children.create!(:name => "a_b_a")

    assert_equal [a_b, a, root], a_b_a.ancestors
  end

  test "#self_and_ancestors" do
    clear_all
    root = post("root")
    a = root.children.create!(:name => "a")
    b = root.children.create!(:name => "b")
    a_a = a.children.create!(:name => "a_a")
    a_b = a.children.create!(:name => "a_b")
    a_b_a = a_b.children.create!(:name => "a_b_a")

    assert_equal [a_b_a, a_b, a, root], a_b_a.self_and_ancestors
  end

  test "#all_children" do
    clear_all
    root = post("root")
    child1 = root.children.create!(:name => "child1")
    child2 = root.children.create!(:name => "child2")
    child11 = child1.children.create!(:name => "child11")
    child12 = child1.children.create!(:name => "child12")
    child121 = child12.children.create!(:name => "child121")

    assert_equal [child121], child12.all_children(:reload => true)
    assert_equal [child11, child12, child121], child1.all_children(:reload => true)
    assert_equal [], child2.all_children(:reload => true)
    assert_equal [child1, child2, child11, child12, child121], root.all_children(:reload => true)
  end

  test "#all_children_count" do
    clear_all
    root = post("root")
    child1 = root.children.create!(:name => "child1")
    child2 = root.children.create!(:name => "child2")
    child11 = child1.children.create!(:name => "child11")
    child12 = child1.children.create!(:name => "child12")
    child121 = child12.children.create!(:name => "child121")

    assert_equal 1, child12.all_children_count(:reload => true)
    assert_equal 3, child1.all_children_count(:reload => true)
    assert_equal 0, child2.all_children_count(:reload => true)
    assert_equal 5, root.all_children_count(:reload => true)
  end

  test "move node" do
    clear_all
    root = post("root")
    a = root.children.create!(:name => "a")
    a_a = a.children.create!(:name => "a_a")
    a_b = a.children.create!(:name => "a_b")
    b = root.children.create!(:name => "b")
    c = root.children.create!(:name => "c")

    assert_equal [a_a,a_b], a.all_children(:reload => true)
    assert_equal [a,root], a_a.ancestors
    assert_equal [a,root], a_b.ancestors

    a.update_attributes!(:parent => b)

    assert_equal [a,a_a,a_b], b.all_children(:reload => true)
    assert_equal [b,root], a.ancestors
    assert_equal [a,b,root], a_a.ancestors
    assert_equal [a,b,root], a_b.ancestors
  end

  test "#children_count" do
    root = post("root")
    a = root.children.create!(:name => "a")
    a_a = a.children.create!(:name => "a_a")
    a_b = a.children.create!(:name => "a_b")

    assert_equal 1, root.children_count
    assert_equal 2, a.children_count
    assert_equal 0, a_a.children_count
    assert_equal 0, a_b.children_count
  end

  test "sort_as_tree" do
    clear_all
    root = post("root")
    a = root.children.create!(:name => "a")
    a_a = a.children.create!(:name => "a_a")
    a_b = a.children.create!(:name => "a_b")
    a_a_a = a_a.children.create!(:name => "a_a_a")
    b = root.children.create!(:name => "b")
    c = root.children.create!(:name => "c")
    c_a = c.children.create!(:name => "c_a")
    b_a = b.children.create!(:name => "b_a")

    sorted_nodes = Post.sort_as_tree [b_a, b, c, a, a_b, a_a_a, c_a, a_a, root]

    assert_equal 0, sorted_nodes.index(root)
    assert_equal 1, sorted_nodes.index(a)
    assert_equal 2, sorted_nodes.index(a_a)
    assert_equal 3, sorted_nodes.index(a_a_a)
    assert_equal 4, sorted_nodes.index(a_b)
    assert_equal 5, sorted_nodes.index(b)
    assert_equal 6, sorted_nodes.index(b_a)
    assert_equal 7, sorted_nodes.index(c)
    assert_equal 8, sorted_nodes.index(c_a)
  end

  def post(name, options = {})
    Post.create!({ :name => name}.merge!(options))
  end

  def clear_all
    Post.delete_all
    ActiveRecord::Base.connection.execute("DELETE FROM posts_tree")
  end
end
