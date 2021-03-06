class ReviewedProfile
  include Mongoid::Document
  include Utiloid

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