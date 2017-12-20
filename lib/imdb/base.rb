module Imdb
  # Represents something on IMDB.com
  class Base
    attr_accessor :id, :url, :title, :also_known_as

    # Initialize a new IMDB movie object with it's IMDB id (as a String)
    #
    #   movie = Imdb::Movie.new("0095016")
    #
    # Imdb::Movie objects are lazy loading, meaning that no HTTP request
    # will be performed when a new object is created. Only when you use an
    # accessor that needs the remote data, a HTTP request is made (once).
    #
    def initialize(imdb_id, title = nil)
      @id = imdb_id
      @url = "http://www.imdb.com/title/tt#{imdb_id}/combined"
      @title = title.delete('"').strip if title
    end

    # Returns an array with cast members
    def cast_members
      document.search('table.cast_list td[@class="itemprop"] a').map { |link| link.content.strip } rescue []
    end

    def cast_member_ids
      document.search('table.cast_list td[@class="itemprop"] a').map { |l| l['href'][/nm\d+/] }
    end

    # Returns an array with cast characters
    def cast_characters
      document.search('table.cast_list td[@class="character"]').map { |link| link.content.strip } rescue []
    end

    # Returns an Hash with cast members and characters
    def cast_members_characters
      memb_char = {}
      cast_members.each_with_index do |_m, i|
        memb_char[cast_members[i]] = cast_characters[i]
      end
      memb_char
    end

    # Returns an Hash with cast members id and characters
    def cast_member_ids_characters
      memb_char = {}
      cast_member_ids.each_with_index do |_m, i|
        memb_char[cast_member_ids[i]] = cast_characters[i]
      end
      memb_char
    end

    def cast_member_id_name_characters
      memb_char = {}
      man = cast_members_characters
      cast_member_ids.each_with_index do |_m, i|
        memb_char[cast_member_ids[i]] = [cast_members[i], cast_characters[i]]
      end
      memb_char
    end

    # Returns the name of the director
    def director
      document.search("h5[text()^='Director'] ~ div a").map { |link| link.content.strip } rescue []
    end

    def director_ids
      document.search("h5[text()^='Director'] ~ div a").map { |link| link['href'].split('/')[2] } rescue []
    end

    def director_ids_hash
      memb_char = {}
      man = cast_members_characters
      director_ids.each_with_index do |_m, i|
        memb_char[_m] = [director[i]]
      end
      memb_char
    end

    # Returns the names of Writers
    def writers
      writers_list = []

      fullcredits_document.search("h4[text()^='Writing Credits'] + table tbody tr td[class='name']").each_with_index do |name, _i|
        writers_list << name.content.strip unless writers_list.include? name.content.strip
      end rescue []

      writers_list
    end

    # Returns the names of Writers
    def writers_ids
      writers_list = []

      fullcredits_document.search("h4[text()^='Writing Credits'] + table tbody tr td[class='name'] a").each_with_index do |name, _i|
        writers_list << name['href'].split('/')[2] unless writers_list.include? name['href'].split('/')[2]
      end rescue []

      writers_list.uniq
    end

    def award_name
      awards_document.xpath("//div[@id='content-2-wide']/div[@id='main']/div/div[@class='article listo']/h3").map { |a| a.text.strip } rescue []
    end

    def awards_table
      awards = {}
      award_name.each do |movie|
        movietest = movie[/.*[^A-Za-z ]/]
        movietest = movietest.split('"')[0]
        movie1 = movie.delete("\n")
        temp = {}

        # puts movietest
        abc = awards_document.search("h3:contains(\"#{movietest}\") ~ table")[0]
        # puts movie,abc
        list = abc.search('td @rowspan').map(&:text)
        list1 = abc.search('td[@rowspan]').map { |a| a.text.delete("\n").delete('"').strip.split(/\s{2,}/) }
        abcd = abc.search('td:last-child')
        listwon = abcd[0...list[0].to_i] if list.size >= 1
        listnom = abcd[list[0].to_i...list[0].to_i + list[1].to_i] if list.size >= 2
        list2nd = abcd[list[0].to_i + list[1].to_i...list[0].to_i + list[1].to_i + list[2].to_i] if list.size >= 3
        list3rd = abcd[list[0].to_i + list[1].to_i + list[2].to_i...list[0].to_i + list[1].to_i + list[2].to_i + list[3].to_i] if list.size >= 4
        list4th = abcd[list[0].to_i + list[1].to_i + list[2].to_i + list[3].to_i...list[0].to_i + list[1].to_i + list[2].to_i + list[3].to_i + list[4].to_i] if list.size >= 5
        listwon.each do |a|
          name = a.at('text()').text.strip
          to = a.search('a @href').map { |a| a.text.split('?')[0].gsub('/name/', '') if !a.text.include?('title') && !a.text.include?('company') && !a.text.include?('javascript') }.compact
          extra = a.search('div text()').text.strip
          if (!to.nil? && !to.empty?) || (!name.nil? && name.present?)
            temp[list1[0]] = [] if temp[list1[0]].nil?
            temp[list1[0]] += [[name, to, extra]]
          end
        end
        unless list1[1].nil?
          listnom.each do |a|
            name = a.at('text()').text.strip
            to = a.search('a @href').map { |a| a.text.split('?')[0].gsub('/name/', '') if !a.text.include?('title') && !a.text.include?('company') && !a.text.include?('javascript') }.compact
            extra = a.search('div text()').text.strip
            if (!to.nil? && !to.empty?) || (!name.nil? && name.present?)
              temp[list1[1]] = [] if temp[list1[1]].nil?
              temp[list1[1]] += [[name, to, extra]]
            end
          end
        end
        unless list1[2].nil?
          list2nd.each do |a|
            name = a.at('text()').text.strip
            to = a.search('a @href').map { |a| a.text.split('?')[0].gsub('/name/', '') if !a.text.include?('title') && !a.text.include?('company') && !a.text.include?('javascript') }.compact
            extra = a.search('div text()').text.strip
            if (!to.nil? && !to.empty?) || (!name.nil? && name.present?)
              temp[list1[2]] = [] if temp[list1[2]].nil?
              temp[list1[2]] += [[name, to, extra]]
            end
          end
        end
        unless list1[3].nil?
          list3rd.each do |a|
            name = a.at('text()').text.strip
            to = a.search('a @href').map { |a| a.text.split('?')[0].gsub('/name/', '') if !a.text.include?('title') && !a.text.include?('company') && !a.text.include?('javascript') }.compact
            extra = a.search('div text()').text.strip
            if (!to.nil? && !to.empty?) || (!name.nil? && name.present?)
              temp[list1[3]] = [] if temp[list1[3]].nil?
              temp[list1[3]] += [[name, to, extra]]
            end
          end
        end
        unless list1[4].nil?
          list4th.each do |a|
            name = a.at('text()').text.strip
            to = a.search('a @href').map { |a| a.text.split('?')[0].gsub('/name/', '') if !a.text.include?('title') && !a.text.include?('company') && !a.text.include?('javascript') }.compact
            extra = a.search('div text()').text.strip
            next unless (!to.nil? && !to.empty?) || (!name.nil? && name.present?)

            temp[list1[4]] = [] if temp[list1[4]].nil?
            temp[list1[4]] += [[name, to, extra]]
          end
        end
        awards[movie1] = temp unless temp.empty?
      end
      awards
    end

    def writers_ids_hash
      memb_char = {}
      writers_ids.each_with_index do |_m, i|
        memb_char[_m] = [writers[i]]
      end
      memb_char
    end

    # Returns the url to the "Watch a trailer" page
    def trailer_url
      'http://imdb.com' + document.at("a[@href*='/video/screenplay/']")['href'] rescue nil
    end

    # Returns an array of genres (as strings)
    def genres
      document.search("td[text()='Genres'] ~ td ul li a").map { |link| link.content.strip } rescue []
    end

    # Returns an array of languages as strings.
    def languages
      document.search("td[text()='Language'] ~ td ul li a").map { |link| link.content.strip } rescue []
    end

    # Returns an array of countries as strings.
    def countries
      document.search("td[text()='Country'] ~ td a[@href*='/country/']").map { |link| link.content.strip } rescue []
    end

    # Returns the duration of the movie in minutes as an integer.
    def length
      document.search("td[text()='Runtime'] ~ td ul li").text[/\d+ min/].to_i rescue nil
    end

    # Returns the company
    def company
      document.search("h5[text()='Company:'] ~ div a[@href*='/company/']").map { |link| link.content.strip }.first rescue nil
    end

    # Returns a string containing the plot.
    def plot
      sanitize_plot(document.at("h5[text()='Plot:'] ~ div").content) rescue nil
    end

    # Returns a string containing the plot summary
    def plot_synopsis
      doc = Nokogiri::HTML(Imdb::Movie.find_by_id(@id, :synopsis))
      doc.at("div[@id='swiki.2.1']").content.strip rescue nil
    end

    def plot_summary
      doc = Nokogiri::HTML(Imdb::Movie.find_by_id(@id, :plotsummary))
      doc.at('p.plotSummary').inner_html.gsub(/<i.*/im, '').strip.imdb_unescape_html rescue nil
    end

    def awards
      document.search("h5[text()='Awards:'] ~ div").map { |link| link.content.strip.gsub("\nSee more »", '').tr("\n", ' ') } rescue nil
    end

    # Returns a string containing the URL to the movie poster.
    def poster
      src = document.at('.subpage_title_block a img')['src'] rescue nil
      case src
      when /^(https:.+@@)/
        Regexp.last_match[1] + '.jpg'
      when /^(https:.+?)\.[^\/]+$/
        Regexp.last_match[1] + '.jpg'
      end
    end

    # Returns a float containing the average user rating
    def rating
      document.at('.ipl-rating-star__rating').content.split('/').first.strip.to_f rescue nil
    end

    # Returns an int containing the Metascore
    def metascore
      criticreviews_document.at('//span[@itemprop="ratingValue"]').content.to_i rescue nil
    end

    # Returns an int containing the number of user ratings
    def votes
      document.at('.ipl-rating-star__total-votes').content.strip.gsub(/[^\d+]/, '').to_i rescue nil
    end

    # Returns a string containing the tagline
    def tagline
      document.search("h5[text()='Tagline:'] ~ div").first.inner_html.gsub(/<.+>.+<\/.+>/, '').strip.imdb_unescape_html rescue nil
    end

    # Returns a string containing the mpaa rating and reason for rating
    def mpaa_rating
      document.at("//a[starts-with(.,'MPAA')]/../following-sibling::*").content.strip rescue nil
    end

    # Returns a string containing the title
    def title(force_refresh = false)
      if @title && !force_refresh
        @title
      else
        @title = document.xpath("//div[@id='tn15title']/h1/text()").text.strip
      end
    end

    def type
      (document.search("span[class='title-extra']").text.include?('TV series') || document.search("div[id='tn15epnav']").text.include?('Episodes'))
    end

    # Returns an integer containing the year (CCYY) the movie was released in.
    def year
      document.at("h3[@itemprop='name'] span").content[/\d+/].to_i rescue nil
    end

    # Returns release date for the movie.
    def release_date
      sanitize_release_date(document.at("a[@href*='releaseinfo']").content[/\d{2}\s\S{3}\s\d{4}/]) rescue nil
    end

    # Returns filming locations from imdb_url/locations
    def filming_locations
      locations_document.search('#filming_locations_content .soda dt a').map { |link| link.content.strip } rescue []
    end

    # Returns alternative titles from imdb_url/releaseinfo
    def also_known_as
      releaseinfo_document.search('#akas tr').map do |aka|
        {
          version: aka.search('td:nth-child(1)').text,
          title:   aka.search('td:nth-child(2)').text
        }
      end rescue []
    end

    # Returns a new Nokogiri document for parsing.
    def document
      @document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id))
    end

    def locations_document
      @locations_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'locations'))
    end

    def releaseinfo_document
      @releaseinfo_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'releaseinfo'))
    end

    def fullcredits_document
      @fullcredits_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'fullcredits'))
    end

    def criticreviews_document
      @criticreviews_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'criticreviews'))
    end

    def awards_document
      @awards_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'awards'))
    end

    # Use HTTParty to fetch the raw HTML for this movie.
    def self.find_by_id(imdb_id, page = :combined)
      try = 0
      begin
        open("http://www.imdb.com/title/tt#{imdb_id}/#{page}")
      rescue
        if try <= 3
          puts 'aaaaaa'
          try += 1
          sleep(2)
          retry
        end
      end
    end

    # Convenience method for search
    def self.search(query)
      Imdb::Search.new(query).movies
    end

    def self.top_250
      Imdb::Top250.new.movies
    end

    def sanitize_plot(the_plot)
      the_plot = the_plot.gsub(/add\ssummary|full\ssummary/i, '')
      the_plot = the_plot.gsub(/add\ssynopsis|full\ssynopsis/i, '')
      the_plot = the_plot.gsub(/see|more|\u00BB|\u00A0/i, '')
      the_plot = the_plot.gsub(/\|/i, '')
      the_plot.strip
    end

    def sanitize_release_date(the_release_date)
      the_release_date.gsub(/see|more|\u00BB|\u00A0/i, '').strip
    end
  end # Movie
end # Imdb
