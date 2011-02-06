class Plugin::Forom < Plugin::Base
  INDEX = 0
  ICONE = 'forom.ico'
  NAME = 'seriessub'
  @@forom_key = nil
  
  def self.forom_key=(new_value)
    @@forom_key = new_value
  end
  def self.forom_key
    @@forom_key
  end
  
  def get_from_source
    item = current.candidats[idx_candidat]
    FileCache.get_srt(item.lien)
  end

  def do_search
    foundTmp = 0
    
    # Recherche de la page de sous titres
    if @lastSearchForom == current.serie+current.saison.to_s
      monURL = @urlForom
    else
      monURL = "http://www.foromtv.com/documents/indexnew.php?#{self.class.forom_key}"
      doc = FileCache.get_html(monURL)
      doc.search("table.conteneur table.conteneur table.contour table.conteneur tr[@class*='int']").each do |k|
        k.search("tr.menu2 b").each do |k2|
          if k2.text.to_s.downcase.match(current.serie.downcase)
            foundTmp = 1
            break
          end
        end
        if foundTmp == 1
          foundTmp = 0
          saisonref = k.text.to_s.scan(/.*saison ([0-9]*)/)
          k.search("td").each do |k2|
            if k2.text.match("ici")
              val = k2.search("a").attr("href").gsub(/[0-9]/, current.saison.to_s)
              monURL = "http://www.foromtv.com/documents/#{val}&#{self.class.forom_key}"
              break
            end
          end
          break
        end
      end

      # Optimisation de recherche
      @lastSearchForom = current.serie+current.saison.to_s
      @urlForom = monURL
    end


    # Recherche des sous titres
    doc = FileCache.get_html(monURL)
    pattern1 = sprintf("s%02de%02d", current.saison, current.episode)
    pattern2 = sprintf("S%02dE%02d", current.saison, current.episode)
    pattern3 = sprintf("%d%02d", current.saison, current.episode)
    pattern4 = sprintf("%dx%02d", current.saison, current.episode)
    pattern = pattern1+"|"+pattern2+"|"+pattern3+"|"+pattern4
    doc.search("table table table tr[@class*='bg']").collect do |k|
      if k.text.to_s.match(pattern) != nil
        vers = k.search("td.h30 a").attr("href").to_s.gsub(/javascript:openThis../, "").gsub(/., ._blank.../, "")
        rel = k.search("td.menu2").text.to_s.scan(/([0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9])/)
        nomFile = k.search("td.h30 a").text.to_s

        new_ligne = WebSub.new
        new_ligne.fichier = nomFile.to_s
        new_ligne.date = rel.to_s
        new_ligne.lien = vers.to_s
        new_ligne.referer = monURL
        new_ligne
      end
    end
  end
end
