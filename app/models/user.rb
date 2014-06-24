require 'mongo_mapper'

class User
  include MongoMapper::Document

  key :name,     String
  key :email,     String
   
  timestamps!

  many :reviewed_profiles, class_name:"ReviewedProfile"

  @@AddNewProfileChance = 0.333

  def prime_reviews(n=3)
    n.times {add_new_profile_for_review}
    raise "couldn't add 3 profiles!" if reviewed_profiles.length < 3
  end

  def next_choice_pair
    initial = reviewed_profiles.min_by{|rp| rp.review_count}

    #let [exclude] be the set of all reviewed movies that have been paired with [initial], along with [initial] itself
    exclude = Set.new([initial.profile_id])
    initial.beats.each  {|pid| exclude.add(pid)}
    initial.beaten_by.each  {|pid| exclude.add(pid)}

    possible_ids = (Set.new(reviewed_profiles.map{|rp| rp.profile_id}) - exclude).to_a

    #if they are unlucky enough to exhaust all pairs without ever getting new profiles added, handle that
    if possible_ids.length == 0
      logger.warn "User #{_id} ran out of pairs"
      raise Exception.new("Needed new profile couln't be created") unless new_rp = add_new_profile_for_review
      return [initial.profile, new_rp.profile]
    end

    return [initial.profile, rprofile_from_pid(possible_ids.sample).profile]
  end

  def add_pick(winner_id, runnerup_id, options={})
    winner_rp = rprofile_from_pid(winner_id)
    runnerup_rp = rprofile_from_pid(runnerup_id)

    raise Exception.new "Profile(s) not in review." unless winner_rp && runnerup_rp

    winner_rp.beat(runnerup_rp)
    save!

    #chance of adding a new profile to the menu
    if !options[:no_new_profile] and rand > @@AddNewProfileChance
      new_rp = self.add_new_profile_for_review
      logger.warn("new profile was to be added, but couldn't be created") unless new_rp
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
      return nil
    end

    rprofile = ReviewedProfile.new(profile)
    reviewed_profiles << rprofile
    save!
    return rprofile
  end

  def pick_count
    reviewed_profiles.inject(0){|memo, rp| memo+rp.beats.length}
  end

  def rprofile_from_pid(pid)
    ind = self.reviewed_profiles.rindex{|rp| rp.profile_id.to_s == pid.to_s}
    ind ? self.reviewed_profiles[ind] : nil
  end

end