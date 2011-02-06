class Plugin::Podnapisi < Plugin::Base
  INDEX = 1
  ICONE = 'podnapisi.ico'
  NAME = 'podnapisi'

  def get_from_source
    item = current.candidats[idx_candidat]

    # Analyse de la page de download
    monURL = File.join("http://www.podnapisi.net", item.lien)
    doc = FileCache.get_html(monURL)

    # FIXME: est ce que cette boucle est parce qu'il y a plusieurs liens, ou bien parce que la notion de doc.at
    # n'est pas connue pour retrouver directement un unique element?
    link = doc.search("div.podnapis_tabele_download a").collect do |k|
      k.attr("href")
    end.compact.last.to_s

    # Récupération du sous titre
    FileCache.get_zip(File.join("http://www.podnapisi.net", link), "None")
  end

  def do_search
    monURL = "http://www.podnapisi.net/ppodnapisi/search?tbsl=3&asdp=0&sK=#{current.serie.gsub(/ /, '+')}&sJ=8&sT=1&sY=&sAKA2=1&sR=&sTS=#{current.saison}&sTE=#{current.episode}"

    # Trouver la page de la serie :
    doc = FileCache.get_html(monURL)
    doc.search("div[@class*='seznambg'] tr[@class*='bg']").collect do |k|
      if k.inner_html.to_s.match(/-sous-titres-p/im)
        listetd = k.search("td")

        new_ligne = WebSub.new
        new_ligne.fichier = k.at(".release").text
        new_ligne.date = k.at("td:nth-of-type(7)").text
        new_ligne.lien = k.at("td:nth-of-type(1) a")['href']
        new_ligne.referer = monURL
        new_ligne
      end
    end
  end
end