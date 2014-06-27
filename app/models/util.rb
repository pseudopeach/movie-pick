class Util
require 'net/http'
require 'net/https'
def self.json_api_get base_URI, params=nil, cookie=""

    response = {raw: (Net::HTTP.get_response(base_URI,"/"+Util.hash_to_qs(params))) }
    #puts "cookie#{cookie.inspect}" if cookie
    #request = Net::HTTP::Get.new(  "#{uri.request_uri}#{Util.hash_to_qs params}" , {"Cookie"=>cookie} )
    
    #response = {:raw=>http.request(request)}
    #response[:cookie] = response[:raw].response['set-cookie'] if response[:raw].response

    begin
      response[:parsed] = JSON.parse response[:raw].body
    rescue
      puts "parse failed"
      puts response[:raw].body.inspect
    end
    return response[:parsed]
  end
  
  def self.hash_to_qs hash, options=nil
    str = ""
    return str if !hash
    str += "?" if !(options && options[:append])
    hash.each_pair do |key,value|
      str += "#{key}=#{URI.encode(value.to_s)}&"
    end
    return str.chop!
  end

end
=begin
module Util::MongoidExtensions
  def self.included receiver
    receiver.extend ClassMethods
  end

  module ClassMethods
    def references(name, options={})
      name_s = name.to_s
      key_name = (name_s+"_id").to_sym

      @cache = {}
      #class_name = options[:class_name] ? options[:class_name] : (name_s.camelize)
      #model_class = class_name.constantize
      #col_name = :id # options[:column_name] ? options[:column_name] : "id"

      attr_accesor (key_name)
      #attr_accesor (name)

      define_method name.to_sym do
        return nil unless self[key_name]
        unless obj = cache[name]
          class_name.where(:id => self[key_name])
        end
      end

      define_method name.to_sym do
        return @loaded_xdata[name] if @loaded_xdata[name]
        key = @xdata[name_s+"_id"]
        return nil unless key
        @loaded_xdata[name] = model_class.find_by_id(key)
        return @loaded_xdata[name]
      end
      define_method "#{name.to_s}=".to_sym do |input|
        @loaded_xdata[name] = input
        @xdata[(name_s+"_id").to_sym] = input.send col_name
      end
    end #xattr
  end #ClassMethods

  def serialize_data
    self.data = @xdata.empty? ? nil : @xdata.to_json
  end
  def deserialize_data
    @xdata = self.data ? JSON(self.data) : {}
    @loaded_xdata = {}
  end

end
=end