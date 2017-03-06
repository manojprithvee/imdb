module Imdb
    class People
        attr_accessor :id, :url, :name

        def initialize(imdb_id, title = nil)
            @id = imdb_id
            @url = "http://www.imdb.com/name/#{imdb_id}/bio"
            @name = title.gsub(" - Biography - IMDb", '').strip if title
        end
        def dob

        end
        def gender
            "http://www.imdb.com/name/#{imdb_id}/"
        end
        def bio
        end
        def spouce
        end
        def height
        end
        def nickname
        end
        def death
        end
        def Birth Name
        end
    end
end