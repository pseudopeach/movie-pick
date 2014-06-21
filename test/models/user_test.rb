require 'test_helper'
require 'minitest/autorun'
require 'Set'

class UserTest < MiniTest::Unit::TestCase

  def setup
    Movie.create title: "Jurassic Park", year: 1991
    Movie.create title: "Gattaca", year: 1997
    Movie.create title: "Star Wars", year: 1978
    puts "there are #{Movie.all.size} movies."
  end

  def teardown
    Movie.destroy_all
  end

  def test_add_user_and_prime_profiles
    u = User.new
    u.prime_reviews

    profile_ids = Set.new(u.reviewed_profiles.map{|rp| rp.profile._id.to_s})

    assert(u.reviewed_profiles.length > 0, "no profiles were added")
    assert_equal(u.reviewed_profiles.length, profile_ids.length, "some reviewed profiles not unique")
  end

  def test_choice_pair_is_well_formed
    u = User.new
    u.prime_reviews

    m1, m2 = u.next_choice_pair
    assert_kind_of(Movie, m1, "first choice wasn't a movie")
    assert_kind_of(Movie, m2, "second choice wasn't a movie")
    assert(m1._id.to_s != m2._id.to_s, "choices are the same")
  end

  def test_add_pick_works_and_pairs_are_unique
    u = User.new
    u.prime_reviews

    (0...3).each do |i|
      m1, m2 = u.next_choice_pair

      assert( !u.profiles_beatten_by(m1._id).member?(m2._id), "#{m1} already beat #{m2}")
      assert( !u.profiles_that_beat(m1._id).member?(m2._id), "#{m2} already beat #{m1}")

      #puts "review counts before add #{u.reviewed_profiles.map{|rr| rr.review_count}.inspect}"
      assert(u.add_pick(m1._id, m2._id, no_new_profile:true), "add_pick failed m1:#{m1}, m2:#{m2}")
      #puts "review counts after add #{u.reviewed_profiles.map{|rr| rr.review_count}.inspect}"

      least_reviewed = u.reviewed_profiles.min_by{|rp| rp.review_count}
      lowest_count = least_reviewed.review_count
      #puts "lowest count found #{lowest_count}, #{least_reviewed.title}"
      assert_equal(i, lowest_count, "lowest count off #{u.reviewed_profiles.map{|rp| rp.review_count}.inspect}")
    end

    assert_equal(3, u.pick_count, "all picks weren't added") #fix
  end

  def test_score_spreads
    u = User.new
    u.prime_reviews

    m1, m2 = u.next_choice_pair
    u.add_pick m1._id, m2._id

    assert(u.rprofile_from_pid(m1._id).score > u.rprofile_from_pid(m2._id).score, "scores upside down")
    assert_in_delta(u.rprofile_from_pid(m1._id).score,-u.rprofile_from_pid(m2._id).score,0.00001, "scores different")

    #m3 must be new and have score 0 and score or m1 must be > 0
    m3, m4 = u.next_choice_pair

    m1_score_before = u.rprofile_from_pid(m1._id).score
    #m1 wins again
    u.add_pick m1._id, m3._id
    m1_score_after = u.rprofile_from_pid(m1._id).score

    assert((m1_score_after > m1_score_before), "winner score didn't go up")
    assert(u.rprofile_from_pid(m3._id).score < 0, "loser score didn't go down")
    assert((m1_score_after - m1_score_before) < m1_score_before,
           "winner should go up less when beating lower scored profile before:#{m1_score_before} a:#{m1_score_after}")

  end

end