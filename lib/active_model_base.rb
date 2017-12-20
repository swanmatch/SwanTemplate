# encoding: utf-8
module ActiveModelBase
  # 呼び元のクラスメソッドにするメソッド
  module ClassMethods
    # USE Column.value_to_boolean
    include ActiveRecord::ConnectionAdapters

    # setter cast as integer
    def type_int(*instances)
      instances.each do |instance|
        # over_ride attr_accessor's setter_method
        define_method("#{instance}=") do |val|
          self.instance_variable_set("@#{instance}", if val.blank? then nil else val.to_i end)
        end
      end
    end

    # setter cast as Date
    def type_date(*instances)
      instances.each do |instance|
        # over_ride attr_accessor's setter_method
        define_method("#{instance}=") do |val|
          self.instance_variable_set("@#{instance}", if val.blank? then nil elsif(val.class == Date) then val else Date.parse(val) end)
        end
      end
    end

    # setter cast as boolean
    # only [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'] => true
    # else false
    def type_bool(*instances)
      instances.each do |instance|
        # over_ride attr_accessor's setter_method
        define_method("#{instance}=") do |val|
          self.instance_variable_set("@#{instance}", ActiveRecord::Type::Boolean.new.cast(val))
        end
      end
    end
  end

  def self.included(klass)
    # 呼び元に継承させる
    klass.extend ClassMethods
  end

  #
  def attributes
    attrs = {}
    instance_variable_names.each{ |instance_name|
      instance_name.delete!("@")
      key = instance_name.to_sym
      value = self.send(instance_name)
      attrs[key] = value
    }
    attrs
  end
end