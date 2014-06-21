class ChoicePair
  include MongoMapper::EmbeddedDocument


  belongs_to  :winner, class_name:"Movie"
  belongs_to  :runnerup, class_name:"Movie"

  #cached values
  key :winner_title, String
  key :runnerup_title, String

  def initialize(winner,runnerup)
    self.winner = winner
    self.runnerup = runnerup
    self.winner_title = winner.title
    self.runnerup_title = runnerup.title
  end

  def spread
    return 10
  end
  
end