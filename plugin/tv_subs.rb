class Plugin::TVSubs < Plugin::Base

	def get_from_source
		item = current.candidats[idx_candidat]
		FileCache.get_zip("http://www.tvsubs.net/files/#{item.fichier.gsub(/ /, ".")}.fr.zip", "None")
	end

	def do_search
		# Trouver la page de la serie
		if @lastSearchTVSubs == "#{current.serie}#{current.saison}"
			monURL = @urlTVSubs
		else
			monURL = "http://www.tvsubs.net/search.php?q=" + CGI.escape(current.serie.downcase)
			doc = FileCache.get_html(monURL)
			doc.search("div.cont ul.list1 li").each do |k|
				if k.text.to_s.match(/#{current.serie}/im)
					monURL = "http://www.tvsubs.net/"+k.search("a").attr("href").to_s.gsub(/-[0-9].html/, "-#{current.saison}.html")
					break
				end
			end

			# Optimisation de recherche
			@lastSearchTVSubs = "#{current.serie}#{current.saison}"
			@urlTVSubs = monURL
		end

		# Trouver l'épisode
		doc = FileCache.get_html(monURL)
		rec = sprintf("%02d.", current.episode.to_s)
		doc.search("div.cont ul.list1 li").each do |k|
			if k.text.to_s.match(rec)
				monURL = "http://www.tvsubs.net/" + k.inner_html.to_s.scan(/episode-[0-9]*\.html/).to_s
				break
			end
		end

		# Trouver les sous titres
		doc = FileCache.get_html(monURL)
		doc.search("div.cont ul.list1 li").collect do |k|
			if k.inner_html.to_s.match("images/flags/fr.gif")
				new_ligne = WebSub.new
				new_ligne.fichier = k.search("a[@href]").last.text.to_s
				new_ligne.date = k.at("span:nth-of-type(1)").text.to_s
				new_ligne.lien = k.inner_html.to_s.scan(/subtitle-([0-9]*).html/).to_s
				new_ligne
			end
		end
	end
end
