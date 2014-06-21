require 'mongo_mapper'

class User
  include MongoMapper::Document

  key :name,     String
  key :email,     String
   
  timestamps!

  many :reviewed_profiles, class_name:"ReviewedProfile"

  @@AddNewProfileChance = 0.333

  def prime_reviews
    3.times {add_new_profile_for_review}
    raise "couldn't add 3 profiles!" if reviewed_profiles.length < 3
  end

  def next_choice_pair
    initial = reviewed_profiles.min_by{|rp| rp.review_count}

    #let [exclude] be the set of all reviewed movies that have been paired with [initial], along with [initial] itself
    exclude = Set.new([initial.profile_id])
    initial.beats.each  {|pid| exclude.add(pid)}
    initial.beaten_by.each  {|pid| exclude.add(pid)}

    possible_ids = (Set.new(reviewed_profiles.map{|rp| rp.profile_id}) - exclude).to_a

    return [initial.profile, rprofile_from_pid(possible_ids.sample).profile]
  end

  def add_pick(winner_id, runnerup_id, options={})
    winner_rp = rprofile_from_pid(winner_id)
    runnerup_rp = rprofile_from_pid(runnerup_id)

    throw Exception.new "Profile(s) not in review." unless winner_rp && runnerup_rp

    winner_rp.beat(runnerup_rp)
    save!

    #chance of adding a new profile to the menu
    unless options[:no_new_profile]
      self.add_new_profile_for_review if rand <= @@AddNewProfileChance
    end

    return true
  end

  def profiles_beatten_by(pid)
    rp = rprofile_from_pid(pid)
    rp.beats.clone
  end

  def profiles_that_beat(pid)
    rp = rprofile_from_pid(pid)
    rp.beaten_by.clone
  end

  def add_new_profile_for_review
    profile = Movie.least_reviewed(exclude: self.reviewed_profiles.map{|rp| rp.profile})
    if profile
      profile.was_reviewed
    else
      raise "couldn't add new profile"
      return false
    end

    rprofile = ReviewedProfile.new(profile)
    reviewed_profiles << rprofile
    save
  end

  def pick_count
    reviewed_profiles.inject(0){|memo, rp| memo+rp.beats.length}
  end

  def rprofile_from_pid(pid)
    ind = self.reviewed_profiles.rindex{|rp| rp.profile_id.to_s == pid.to_s}
    ind ? self.reviewed_profiles[ind] : nil
  end

end