class ReviewedProfile
  include MongoMapper::EmbeddedDocument

  belongs_to :profile, class_name:"Movie"

  key :score, Float, default:0.0

  #cached values
  key :review_count, Integer, default:0
  key :title, String

  key :beats, Array, default:[] #id list
  key :beaten_by, Array, default:[] #id_list



  def initialize(profile=nil)
    self.review_count = 0
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