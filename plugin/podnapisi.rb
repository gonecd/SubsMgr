class Plugin::Podnapisi < Plugin::Base

	def get_from_source
		item = current.candidats[idx_candidat]

		# Analyse de la page de download
		monURL = File.join("http://www.podnapisi.net", item.lien)
		doc = FileCache.get_html(monURL)
		
		link = nil
		doc.search("div.podnapis_tabele_download a").each do |k|
			link = k.attr("href").to_s
			break if link.match(/download/)
		end

		# Récupération du sous titre
		FileCache.get_zip(File.join("http://www.podnapisi.net", link), "None")
	end

	def do_search
		monURL = "http://www.podnapisi.net/ppodnapisi/search?tbsl=3&asdp=0&sK=#{CGI.escape(current.serie)}&sJ=8&sT=1&sY=&sAKA2=1&sR=&sTS=#{current.saison}&sTE=#{current.episode}"

		# Trouver la page de la serie :
		doc = FileCache.get_html(monURL)
		doc.search("div[@class*='seznambg'] tr[@class*='bg']").collect do |k|
			if k.inner_html.to_s.match(/-sous-titres-p/im)
				new_ligne = WebSub.new
				new_ligne.fichier = "#{k.at(".release").try(:text)}.srt"
				new_ligne.date = k.at("td:nth-of-type(7)").text.strip.split(/[^0-9]+/).reverse.join("-")
				new_ligne.lien = k.at("td:nth-of-type(1) a")['href']
				new_ligne.referer = monURL
				new_ligne
			end
		end
	end
end
