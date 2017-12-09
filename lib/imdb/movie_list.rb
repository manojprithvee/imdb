module Imdb
  class MovieList
    def movies
      @movies ||= parse_movies
    end

    private

    def parse_movies
      result = []
      document.search("a[@href^='/title/tt']").reject do |element|
        element.inner_html.imdb_strip_tags.empty? ||
          element.inner_html.imdb_strip_tags == 'X' ||
          element.parent.inner_html =~ /media from/i
      end.map do |element|
        id = element['href'][/\d+/]
        data = element.parent.inner_html.split('<br />')
        title = !data[0].nil? && !data[1].nil? && data[0] =~ /img/ ? data[1] : data[0]
        title = title.imdb_strip_tags.imdb_unescape_html
        title.gsub!(/\s+\(\d\d\d\d\)$/, '')

        if title =~ /\saka\s/
          titles = title.split(/\saka\s/)
          title = titles.map(&:strip).map(&:imdb_unescape_html).map { |a| a.delete('"') }
        end

        title = [title] if !title.nil? && title.class != Array
        # puts title.inspect
        !title.nil? && title.class == Array && !title.map(&:strip).empty? ? [id, title] : nil
      end.compact.uniq.map do |values|
        # puts values.inspect
        values[1].map do |a|
          z = [values[0], a.split("\n").reject{|a| !a.present? || (a.include? "IMDb") || (a.include? "»")}.map{|a|a.strip}[0]]
          # puts z
          result << Imdb::Movie.new(*z)
        end
      end
      result.flatten.uniq
    end
  end # MovieList
end # Imdb
