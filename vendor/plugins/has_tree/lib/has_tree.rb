module HasTree
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_tree(*args)
      options = args.extract_options!

      belongs_to :parent, :class_name => name, :foreign_key => :parent_id
      has_many :children, :class_name => name, :foreign_key => :parent_id, :dependent => :destroy, :order => options[:order]

      include HasTree::InstanceMethods

      order_by = options[:order] ? "\"#{options[:order].to_s}\"" : "\"nil\""

      class_eval <<-EOV
        after_save do |rec|
          rec.setup_tree_after_save!
        end

        after_destroy do |rec|
          rec.cleanup_tree_after_destroy!
        end

        def self.roots
          all(:conditions => "parent_id IS NULL", :order => #{order_by})
        end

        def self.root
          first(:conditions => "parent_id IS NULL", :order => #{order_by})
        end

        def self.has_tree_table_name
          "#{table_name}_tree"
        end
      EOV
    end

    def sort_as_tree nodes
      array = []
      hash = {}

      nodes.inject({}) do |res, n|
        pos = n.parent_id.to_i
        if res[pos].blank?
          res[pos] = []
        end
        res[pos] << n
        res
      end.each_pair do |k, v|
        hash[k] = v.sort_by { |n| n.name }
      end

      start = hash.keys.sort.first

      reclambda do |this, args|
        h = args[0]
        i = args[1]
        a = args[2]
        h[i].to_a.each do |item|
          array << item
          if h[item.id]
            this.call([h, item.id, a])
          end
        end
      end.call([hash, start, array])

      array
    end

    def reclambda
      #http://hamptoncatlin.com/2007/recursive-lambda-s
      lambda do |f|
        f.call(f)
      end.call(lambda do |f|
                 lambda do |this|
                   lambda do |*args|
                     yield(this, *args)
                   end
                 end.call(lambda do |x|
                            f.call(f).call(x)
                          end)
               end)
    end

    def check_tree
      errors = []
      self.all.each do |it|
        it_error = false

        # without parent
        begin
          it.parent_id && it.parent
        rescue ActiveRecord::RecordNotFound
          is_error = true
          errors << [it, "without parent"]
        end
        next if is_error

        # loops
        max_depth = 10
        idx = 0
        node = it.parent
        while node
          if idx > max_depth
            errors << [it, "loop detected"]
            is_error = true
            break
          end
          node = node.parent
          idx += 1
        end
        next if is_error

        # invalid ancestors
        if it.ancestors != it.recursive_ancestors
          errors << [it, "invalid ancestors"]
          is_error = true
        end
        next if is_error
      end
      return errors
    end

  end

  module InstanceMethods
    def ancestors
      tbl = self.class.has_tree_table_name
      tt = self.class.table_name
      self.class.all(:joins => "INNER JOIN #{tbl} ON #{tbl}.parent_id = #{tt}.id AND #{tbl}.owner_id = #{self.id} AND #{tbl}.parent_id <> #{self.id}",
                     :order => "#{tbl}.level ASC")
    end

    def self_and_ancestors
      [self] + ancestors
    end

    def recursive_ancestors
      node, nodes = self, []
      nodes << node = node.parent while node.parent
      nodes
    end

    def siblings
      self_and_siblings - [self]
    end

    def self_and_siblings
      parent ? parent.children : self.class.roots
    end

    def all_children(options = {})
      if options.delete(:reload)
        @has_tree_all_children = nil
      end
      unless @has_tree_all_children
        tbl = self.class.has_tree_table_name
        tt = self.class.table_name
        options.merge!(:joins => "INNER JOIN #{tbl} ON #{tbl}.owner_id = #{tt}.id AND #{tbl}.parent_id = #{self.id} AND #{tbl}.owner_id <> #{self.id}",
                       :readonly => false)
        @has_tree_all_children = self.class.all(options)
      end
      @has_tree_all_children
    end

    def all_children_count(options = {})
      if options.delete(:reload)
        @has_tree_all_children_count = nil
      end
      unless @has_tree_all_children_count
        tbl = self.class.has_tree_table_name
        tt = self.class.table_name
        @has_tree_all_children_count = ActiveRecord::Base.count_by_sql("SELECT COUNT(*) FROM #{tbl} WHERE #{tbl}.parent_id = #{self.id} AND #{tbl}.owner_id <> #{self.id}")
      end
      @has_tree_all_children_count
    end

    def children_count
      children.count
    end

    def root
      if self.parent_id
        tbl = self.class.has_tree_table_name
        tt = self.class.table_name
        self.class.first(:joins => "INNER JOIN #{tbl} ON #{tbl}.parent_id = #{tt}.id AND #{tbl}.owner_id = #{self.id} AND #{tbl}.parent_id <> #{self.id}",
                         :order => "#{tbl}.level DESC")
      else
        self
      end

    end

    ##########

    def setup_tree_after_save!
      # rebuild all_children_count
      cnt_zero = all_children_count(:reload => true).zero?
      a_s = nil
      if parent_id_changed? || !tree_exists?
        if cnt_zero
          create_tree_entries
        else
          a_s = all_children(:reload => true)
          a_s_ids = a_s.map(&:id) + [self.id]
          cleanup_all_children_tree!(a_s_ids)
          create_tree_entries(:skip_cleanup => true)
          a_s.each do |it|
            it.create_tree_entries(:skip_cleanup => true)
          end
        end
        if respond_to?(:root_id) && r = self.root
          a_s_ids = [self.id]
          unless cnt_zero
            a_s ||= all_children(:reload => true)
            a_s_ids += a_s.map(&:id)
          end
          self.class.update_all(["root_id = ?", r.id], ["id IN (?)", a_s_ids])
        end
      end
      # update children if need
      if respond_to?(:has_tree_update_all_children) && !cnt_zero
        ids = (a_s || all_children(:reload => true)).map(&:id)
        has_tree_update_all_children(ids)
      end
    end

    def cleanup_tree_after_destroy!
      cleanup_tree!
    end

    def cleanup_tree!
      if tree_exists?
        sql = "DELETE FROM #{self.class.has_tree_table_name} WHERE owner_id = #{self.id}"
        ActiveRecord::Base.connection.execute sql
      end
    end

    def tree_exists?
      counter_sql = "SELECT COUNT(*) FROM #{self.class.has_tree_table_name} WHERE owner_id = #{self.id}"
      !self.class.count_by_sql(counter_sql).zero?
    end

    def cleanup_all_children_tree!(ids)
      ids = ids.join(',')
      counter_sql = "SELECT COUNT(*) FROM #{self.class.has_tree_table_name} WHERE owner_id IN (#{ids})"
      unless self.class.count_by_sql(counter_sql).zero?
        sql = "DELETE FROM #{self.class.has_tree_table_name} WHERE owner_id IN (#{ids})"
        ActiveRecord::Base.connection.execute sql
      end
    end

    def create_tree_entries(options = {})
      cleanup_tree! unless options[:skip_cleanup]
      level = 0
      (recursive_ancestors + [self]).each do |it|
        sql = "INSERT INTO #{self.class.has_tree_table_name} (owner_id,parent_id,level) VALUES(#{self.id},#{it.id},#{level})"
        ActiveRecord::Base.connection.execute sql
        level += 1
      end
    end

  end
end
