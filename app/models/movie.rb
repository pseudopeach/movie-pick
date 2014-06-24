require 'mongo_mapper'

class Movie
  include MongoMapper::Document

  key :title,     String
  key :imdb_id,   String
  key :director, String
  key :stars, Array

  key :image_url, String
  key :summary,   String
  key :genre,   String
  key :year,      String

  key :normalized_score, Float, default: 0.0

  key :review_count, Integer, default:0

  timestamps!

  @@High_Review_Threshold = 5

  validates_presence_of :title

  def self.from_seed_file
    logger.debug "new movie profile requested"
    begin
      chosen_line = nil
      File.foreach("/Users/justo/Documents/dev/gable/app/models/movie_titles.json").each_with_index do |line, number|
        chosen_line = line if rand < 1.0/(number+1)
      end

      movie_h = JSON.parse chosen_line
      rails "already stored" if Movie.find(movie_h)

      out = Movie.new(movie_h)
      out.augment_from_omdb
    rescue
      return nil
    end

    logger.info "created #{out.title}"
    return out
  end


  def self.least_reviewed(options={})
    if(exc = options[:exclude])
      excids = exc.map{|r| r._id}
      item = Movie.where(:_id.nin => excids).sort(:review_count).limit(1).first
    else
      item = Movie.sort(:review_count).limit(1).first
    end

    #can remove - specific to seed file
    if(!item || item.review_count > @@High_Review_Threshold)
      return nil if(options[:no_new_seeds])
      m = Movie.from_seed_file
      item = m if m && m.save
    end

    return item
  end

  def was_reviewed
    self.review_count += 1
    save
  end

  def self.from_name(name, options={})
    m = Movie.new
    m.title = name

    options.each{|k,v| m.send(k+"=",v)}
    m.augment_from_omdb
    return m
  end


  @@Movie_Lookup_Base = "www.omdbapi.com"
  def augment_from_omdb(options={})
    mh = Util.json_api_get(@@Movie_Lookup_Base,{t:title, y:year})
    self.genre = mh["Genre"]
    self.year = mh["Year"]
    self.director = mh["Director"]
    self.summary = mh["Plot"]
    self.stars = mh["Actors"].split /,\s*/
    self.imdb_id = mh["imdbID"]
    self.image_url = mh["Poster"]
    return mh["imdbID"] != nil
  end


end