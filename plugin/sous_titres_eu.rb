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
		rec_saison = sprintf("%s\.S0?%s", current.serie.downcase.gsub(/ /, '.'), current.saison, current.saison)

		doc = FileCache.get_html(monURL)
		doc.search("div.saison a").collect do |k|
            
			fichierCible = k.search("span.filenameSerie").text.to_s
			vers = k.attr("href").to_s
			rel = k.search("span.update").text.to_s

			# Cas du zip par episode
			if WebSub.valid_episode?(fichierCible, current.saison, current.episode)
				# Récupération du zip
				path = FileCache.get_file("http://www.sous-titres.eu/series/#{vers}", :zip => true)

				# Exploration du zip
				`zipinfo -1 #{path}`.collect do |entry|
					if WebSub.french?(entry)
						new_ligne = WebSub.new
						new_ligne.fichier = entry.to_s.strip
						new_ligne.date = rel.to_s
						new_ligne.lien = vers.to_s
						new_ligne.referer = monURL
						new_ligne
					end
				end
				# Cas du zip par saison
			elsif k.text.downcase.match(/#{rec_saison}/im)
				# on zappe les zips de saison uniquement en anglais
				next unless WebSub.french?(fichierCible)
				# Récupération du zip
				path = FileCache.get_file("http://www.sous-titres.eu/series/#{vers}", :zip => true)

				# Exploration du zip
				`zipinfo -1 #{path}`.collect do |entry|
					next unless WebSub.valid_episode?(entry, current.saison, current.episode)
					new_ligne = WebSub.new
					new_ligne.fichier = entry.to_s.strip
					new_ligne.date = rel.to_s
					new_ligne.lien = vers.to_s
					new_ligne.source = "SousTitresEU"
					new_ligne.referer = monURL
					new_ligne
				end
			end
		end
	end
end
