module Imdb
    class People
        attr_accessor :id, :url, :name

        def initialize(imdb_id, title = nil)
            @id = imdb_id
            @url = "http://www.imdb.com/name/#{imdb_id}/bio"
            @name = title.gsub(" - Biography - IMDb", '').strip if title
        end

        def dob_place
            a=document.search('td[text()="Date of Birth"] ~ td a').map{|link| link.content.strip} rescue []
        end

        def gender
            gender=home_document.search('div[@class="infobar"] a span').map { |link| link.content.strip }
            return 1 if gender.include?("Actor")
            return 0 if gender.include?("Actress")
            text=document.search('h4[text()*="Mini Bio"] ~ div p').text.downcase.split(" ")
            he=text.count("he")+text.count("him")
            she=text.count("she")+text.count("her")
            puts text
            puts he
            puts she
            return 0 if she>he
            return 1 if she<he
            return -1
        end

        def flims
            home_document.search('div[@id="filmo-head-actor"] ~ div div @id').map{|a|  a.text.gsub("actor-","") if a.text.include?("actor")}.compact rescue []
        end

        def bio
           document.search('h4[text()*="Mini Bio"] ~ div p').map{|link| link.content.strip if !link.content.strip.include?("IMDb Mini Biography") }.compact rescue []
        end

        def spouce
            document.search('table[@id="tableSpouses"] tr td').map{|link| link.content.gsub("  ","").gsub(" \n","").strip } rescue []
        end

        def death
            a=document.search('td[text()="Date of Death"] ~ td a').map{|link| link.content.strip} rescue []
        end

        def self.find_by_id(imdb_id, page = :bio)
            try=0
            begin
            open("http://www.imdb.com/name/#{imdb_id}/#{page}")
            rescue
                if try<=3
                try+=1
                sleep(2)
                retry
                end
            end
        end

        def document
            @document ||= Nokogiri::HTML(Imdb::People.find_by_id(@id))
        end
        
        def home_document
            @home_document ||= Nokogiri::HTML(Imdb::People.find_by_id(@id, ''))
        end
    end
end