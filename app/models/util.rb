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
