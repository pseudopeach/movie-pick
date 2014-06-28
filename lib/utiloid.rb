module Utiloid
  def self.included receiver
    receiver.extend ClassMethods
  end

  module ClassMethods
    def references_doc(name, options={})
      name_s = name.to_s
      key_name = (name_s+"_id")
      class_name = options[:class_name]

      field key_name, type:BSON::ObjectId

      #getter
      define_method name_s do
        @ref_cache ||= {}
        return nil unless key_value = self.send(key_name)

        if @ref_cache.key? name_s
          #value found in instance cache
          value_obj = @ref_cache[name_s]
        else
          #need to look up from db, then cache
          value_obj = class_name.constantize.find(key_value)
          @ref_cache[name_s] = value_obj
        end

        return nil if value_obj._id != key_value #stale cached value, don't return it
        return value_obj
      end

      #setter
      define_method (name_s+"=") do |value_obj|
        @ref_cache ||= {}
        #set key field
        self.send(key_name+"=", value_obj._id)
        @ref_cache[name_s] = value_obj
      end

    end #ref

  end #class methods

end
