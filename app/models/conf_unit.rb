class ConfUnit < ActiveRecord::Base
  acts_as_tree :order => 'name'
  validates_presence_of :name
  serialize :properties, Hash

  def self.kinds
    conf_file_name = File.join(RAILS_ROOT, 'config', 'conf_unit_kinds.yml')
    raise( RuntimeError, "#{conf_file_name} not found" ) unless File.exist?(conf_file_name)
    YAML.load(File.read( conf_file_name ))
  end
  
  def kinds
    self.class.kinds
  end

  def validate
    if properties
      properties.each do |property_name, value|
        if field =CONF_UNIT_KINDS[kind]['fields'].select{|field|field['name'] == property_name}.first
          # Field type validation.
          if field['type'] == 'Fixnum'
            self.errors.add( I18n.t("conf_unit_properties.#{kind}.#{field['name']}"), I18n.t("activerecord.errors.messages.invalid")) if value.match(/[^\d]/)
          end
        else
          # Unknown field found. Can't be normally.
          raise ActiveRecord::RecordInvalid, "Unknown field #{property_name}"
        end
      end
    end
  end

  def before_validation
    self.properties = nil if self.kind_changed?
  end

  def update_properties properties_hash
    self.properties = properties_hash
    save
  end

  def property( property_name )
   properties && properties[property_name]
  end

  def self.generate_status_message
    returning "Статус системы:\n" do |text|
      if (broken_conf_units = self.find_all_by_broken(true)).size > 0
        text << "Сломанные КЕ:\n"
        text << broken_conf_units.collect{|cu|cu.name + (cu.children.size > 0 ? (" (Дочерние КЕ: #{cu.children.map(&:name).join(', ')})") : '')}.join("\n") << "\n"
      else
        text << "Все КЕ работают"
      end
    end
  end

end
