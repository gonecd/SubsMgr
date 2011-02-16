class Plugin::SousTitresEU < Plugin::Base
  INDEX = 3
  ICONE = 'soustitreseu.png'
  NAME = 'soustitreseu'

  def get_from_source
    item = current.candidats[idx_candidat]
    FileCache.get_zip("http://www.sous-titres.eu/series/#{item.lien}", item.fichier)
  end

  def do_search
    monURL = "http://www.sous-titres.eu/series/#{current.serie.downcase.gsub(/ /, '_')}.html"
    rec1 = sprintf("%dx%02d", current.saison, current.episode)
    rec2 = sprintf("%s.s%02d", current.serie.downcase.gsub(/ /, '.'), current.saison)
    rec3 = sprintf("S%02dE%02d", current.saison, current.episode)

    doc = FileCache.get_html(monURL)
    doc.search("div.saison tr").collect do |k|
      # Cas du zip par episode
      if k.text.downcase.match(rec1)
        blk = k.at("td.filename a")
        fichierCible = blk.text
        vers = blk.attr("href").to_s
        rel = k.search("td.update").text.to_s

        # Récupération du zip
        path = FileCache.get_file("http://www.sous-titres.eu/series/#{vers}", :zip => true)

        # Exploration du zip
        `zipinfo -1 #{path}`.collect do |entry|
          if entry.to_s.match(/\.srt/im) && !entry.to_s.match(/\.(EN|VO)\./im)
            new_ligne = WebSub.new
            new_ligne.fichier = entry.to_s.strip
            new_ligne.date = rel.to_s
            new_ligne.lien = vers.to_s
            new_ligne.referer = monURL
            new_ligne
          end
        end.flatten
      # Cas du zip par saison
      elsif k.text.downcase.match(rec2)
        blk = k.at("td.filename a")
        fichierCible = blk.text
        vers = blk.attr("href").to_s
        rel = k.search("td.update").text.to_s

        # Récupération du zip
        path = FileCache.get_file("http://www.sous-titres.eu/series/#{vers}", :zip => true)

        # Exploration du zip
        `zipinfo -1 #{path}`.collect do |entry|
          if entry.to_s.match(/\.srt/im) && entry.to_s.match(rec3) && !entry.to_s.match(/\.(EN|VO)\./im)
            $stderr.puts "... match for #{entry}!"
            new_ligne = WebSub.new
            new_ligne.fichier = entry.to_s.strip
            new_ligne.date = rel.to_s
            new_ligne.lien = vers.to_s
            new_ligne.confiant = get_confiance(new_ligne.fichier.downcase)
            new_ligne.source = "SousTitresEU"
            new_ligne.referer = monURL
            new_ligne
          end
        end
      end
    end
  end
end
