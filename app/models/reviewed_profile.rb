class ReviewedProfile
  include Mongoid::Document


  def self.references_doc(name, options={})
    name_s = name.to_s
    key_name = (name_s+"_id")
    class_name = options[:class_name]

    attr_accessor key_name

    #getter
    define_method name_s do
      @ref_cache ||= {}
      return nil unless key_value = self.send(key_name)

      if @ref_cache.key? name_s
        #value found in instance cache
        value_obj = @ref_cache[name_s]
      else
        #need to look up from db, then cache
        value_obj = class_name.find(key_value)
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

  end




  embedded_in :user #, inverse_of: :reviewed_profiles
  references_doc :profile, class_name: "Movie"

  field :score, type: Float, default:0.0

  #cached values
  field :review_count, type: Integer, default:0
  field :title, type: String

  field :beats, type: Array, default:[] #id list
  field :beaten_by, type: Array, default:[] #id list



  def initialize(profile=nil)
    super(nil)
    if profile
      self.profile = profile
      self.score = profile.normalized_score
      self.title = profile.title
    end
  end

  def beat(other)
    spread = 10.0 / (1.0 + Math.exp((self.score - other.score)/10.0))
    self.was_reviewed(other,spread)
    other.was_reviewed(self,-spread)
  end

  def was_reviewed(other, spread)
    self.review_count += 1
    self.score += spread
    (spread > 0 ? self.beats : self.beaten_by) << other.profile_id
    #puts "*************** beats:#{beats} beaten_by:#{beaten_by}"
    save!
  end



end