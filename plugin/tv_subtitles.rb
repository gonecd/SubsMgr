class Plugin::TVSubtitles < Plugin::Base
  INDEX = 5
  ICONE = 'tvsubtitles.png'
  NAME = 'tvsubtitles'

  def get_from_source
    item = current.candidats[idx_candidat]
    FileCache.get_zip("http://www.tvsubtitles.net/download-#{item.lien}.html", "None")
  end

  def do_search
    # Trouver la page de la serie
    if @lastSearchTVsubtitles == "#{current.serie}#{current.saison}"
      monURL = @urlTVsubtitles
    else
      monURL = "http://www.tvsubtitles.net/search.php?q=" + CGI.escape(current.serie.to_s.downcase)
      doc = FileCache.get_html(monURL)
      doc.search("ul li div[@style='']").each do |k|
        if k.inner_html.to_s.match(/#{current.serie}/im)
          monURL = "http://www.tvsubtitles.net" + k.search("a").attr("href").to_s.gsub(/\.html/, "-#{current.saison}.html")
          break
        end
      end

      # Optimisation de recherche
      @lastSearchTVsubtitles = "#{current.serie}#{current.saison}"
      @urlTVsubtitles = monURL
    end

    # Trouver l'épisode
    $stderr.puts "EPISODE LOOKUP: #{monURL}"
    doc = FileCache.get_html(monURL)
    rec = sprintf("%dx%02d", current.saison.to_s, current.episode.to_s)
    doc.search("table tr[@align='middle']").each do |k|
      if k.inner_html.to_s.match(rec)
        monURL = "http://www.tvsubtitles.net/" + k.search("a").attr("href").to_s
        break
      end
    end

    # Trouver les sous titres
    $stderr.puts "SUBTITLE LOOKUP: #{monURL}"
    doc = FileCache.get_html(monURL)
    doc.search("a[@href]").collect do |k|
      next unless (k.at("img") || {})['src'].to_s.match(/fr\.(gif|png|jpg)/im)
      $stderr.puts k.to_s

      new_ligne = WebSub.new
      new_ligne.fichier = "#{current.serie}.#{rec}." + k.search("p[@title='rip']").text.scan(/[0-9]*\ *[a-zA-Z]*/).to_s + "-" + k.search("p[@title='release']").text.scan(/[0-9]*\ *[a-zA-Z]*/).to_s
      new_ligne.date = k.text.to_s.scan(/[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]/).to_s
      new_ligne.lien = k[:href].to_s.scan(/[0-9]*/).to_s
      new_ligne.referer = monURL
      new_ligne
    end
  end
  
end
