class BlogGraph

     
  #@@UserNImage = Regexp.new '<a[^>]* href=".*?(\w+)\.tumblr\.com[^"]*.*?<img[^>]* src="http:\/\/\d+\.media\.tumblr\.com/([^"]+)'
  #@@UserNImageM = Regexp.new '<a[^>]* href=".*?(\w+)\.tumblr\.com[^"]*.*?<img[^>]* src="http:\/\/\d+\.media\.tumblr\.com/([^"]+)',
   #  Regexp::MULTILINE
   
   @@Image_Tag = Regexp.new '<img[^>]* src="http:\/\/\d+\.media\.tumblr\.com/([^"]+)'
   @@Blog_Link = Regexp.new '<a[^>]* href=".*?(\w+)\.tumblr\.com[^"]*'
   
  def self.add_images(page_limit)
    list = Blog.where("status = 'good' AND checked_on IS NULL")
    
    list.each do |blog|
      image = nil
      
      for i in (1..page_limit)
        puts "starting #{blog.id} #{i}..."
        suffix = i>1 ? "/page/#{i}" : "" 
        raw_html = Util.json_api_get("http://#{blog.id}.tumblr.com#{suffix}")[:raw].body
        
        images = raw_html.scan(@@Image_Tag)
        links = raw_html.scan(@@Blog_Link)
            
        images.each do |iid|
          image = TumblrImage.find_or_initialize_by_id(iid[0])
          image.found_on_id ||= blog.id
          
          begin
            blog.tumblr_images << image 
          rescue ActiveRecord::RecordNotUnique
          end
          
        end
        
        links.each do |bid|
          nblog = Blog.find_or_create_by_id(bid[0])
        end
        
        sleep(rand(40).to_f/30.0)
      end #pages
      
      blog.checked_on = 0.seconds.ago
      blog.oldest_image_id = (image ? image.id : nil)
      blog.save

    end #blog

  end
  
  def self.crawl(limit, startpoint=nil, page_limit=2)
    #depricated
    done = 0
    
    blog_queue = BlogGraph.list_unexplored startpoint
    blog_queue << startpoint if blog_queue.length == 0
    puts "starting with: #{blog_queue.inspect}"
    while done < limit && blog_queue.length > 0
      blog = blog_queue.shift
      
      BlogGraph.explore_blog blog, :seed=>startpoint, :pages=>page_limit
      done += 1
      
      #refill empty blog queue
      blog_queue = BlogGraph.list_unexplored startpoint if blog_queue.length==0
    end
    
    puts "DONE! There are now #{TumblrImage.count} records."
  end
  
  def self.checkname(name)
    result = false
    BlogGraph.bad.each do |b|
      return false if name.include? b
    end
    BlogGraph.good.each do |g|
      return true if name.include? g
    end
    return false
  end
  
  def self.und
    Blog.where(:status =>"unknown")
  end
  
  def self.filter
    #list = BlogGraph.und.sample(20)
    list = BlogGraph.und.select{|q| BlogGraph.checkname q.id}.sample(20)
    BlogGraph.decide(list)
    siz = list = BlogGraph.und.select{|q| BlogGraph.checkname q.id}.size
    puts "**** Only #{siz} left! ****"
  end
  
  def self.decide(blogs)
    blogs_out = []
    blogs.each do |blog|
      puts "keep #{blog.id}"
      input = gets.chomp!
      unless input == ""
        blog.status = "good"
      else
        blog.status = "eliminated"
      end
      
    end
    blogs.each {|b| b.save}
  end
  
  def self.explore_blog(name, options={})
    #depricated
    page_limit = options[:pages] ||= 1
    added = 0
    found = 0
    last_found = ""
    
    for i in (1..page_limit)
      suffix = i>1 ? "/page/#{i}" : "" 
      raw_html = Util.json_api_get("http://#{name}.tumblr.com#{suffix}")[:raw].body
      
      items = BlogGraph.find_url_pairs(raw_html)
      found += items.length
      
      break if items.length == 0
      
      items.each do |item|
        last_found = item[1]
        added += 1 if TumblrImage.add_one(item[1],item[0],name,options[:seed])
      end 
    end
    if found > 0
      bl = ExploredBlog.find_by_id(name)
      unless bl
        bl = ExploredBlog.new
        bl.id = name
      end
      
      bl.oldest_img_url = last_found
      bl.save
      puts "#{name}: found #{found}, #{added} new."
    end
    
  end
  
  def self.list_unexplored(seeded_by=nil)
    rec_list = TumblrImage.select("distinct user").where("user NOT IN (select id from explored_blogs)")
    rec_list = rec_list.where(:seed_blog_id=>seeded_by) if seeded_by
    list = rec_list.map {|q| q.user}
    list -= ["www"]
    return list
  end
     
  def self.find_url_pairs(input)
    items = input.scan(@@UserNImage)
    if items.length == 0
      items = input.scan(@@UserNImageM)
    end     
    return items
  end
end
