require 'test_helper'
require 'minitest/autorun'
require 'Set'

class UserTest < MiniTest::Unit::TestCase

  def setup
    @m1 = Movie.create title: "Jurassic Park", year: 1991
    @m2 = Movie.create title: "Gattaca", year: 1997
    @m3 = Movie.create title: "Star Wars", year: 1978
    puts "there are #{Movie.all.size} movies."
  end

  def teardown
    Movie.destroy_all
  end

  def test_user_saves_profiles
    u1 = User.new
    u1.add_new_profile_for_review
    u1.save

    u2 = User.find(u1._id)
    assert_equal(1, u2.reviewed_profiles.length, "user has no attached RP record")
    rprofile = u2.reviewed_profiles.first
    assert(rprofile.profile, "attached rp record had no profile reference")
    assert_includes(Movie.all,u2.reviewed_profiles.first.profile, "profile not in possible set")

  end


end