# TODO: recursive Zip quand un zip de saison contient les zips de chaque épisode
# ex: Dexter.S5 => http://www.seriessub.com/sous-titres/dexter/saison_5/

class Plugin::SeriesSub < Plugin::Base

	def get_from_source
		item = current.candidats[idx_candidat]
		req = "http://www.seriessub.com/download-#{item.lien}.html"
		if item.date.index(" ") == 0
			# Cas du fichier simple
			FileCache.get_srt(req, item.referer)
		else
			# Récupération dans le zip
			FileCache.get_zip(req, item.fichier, item.referer)
		end
	end

	def do_search
		monURL = "http://www.seriessub.com/sous-titres/"+current.serie.downcase.gsub(/ /, '_')+"/saison_"+current.saison.to_s+"/"
		rec1 = sprintf("%s.%d%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)
		rec2 = sprintf("%s.%dx%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)
		rec3 = sprintf("%s.s%d", current.serie.downcase.gsub(/ /, '.'), current.saison)
		rec4 = sprintf("%d%02d", current.saison, current.episode)
		rec5 = sprintf("%dx%02d", current.saison, current.episode)

		doc = FileCache.get_html(monURL, File.dirname(monURL))
		doc.search("#sous-titres-list tr").collect do |k|
			if k.to_s.match(/(#{rec1}|#{rec2})/im) && k.to_s.match(/(vf|fr)/im)
				# Info globales au fichier
				fichierCible = k.at("a.linkst").inner_html
				vers = k.at("a.linkst").attr("href").to_s.scan(/[0-9]*/)
				rel = k.at(".st_update").text.to_s

				# Cas du fichier zip par episode
				#################################
				if fichierCible.to_s.match(/zip/im)
					# Download du zip
					req = "http://www.seriessub.com/download-#{vers}.html"
					path = FileCache.get_file(req, :referer => monURL, :zip => true)

					# Recherche dans le zip
					`zipinfo -1 #{path}`.collect do |entry|
						if !entry.to_s.match(/\.(VO|eng|en)\./im) && entry.to_s.match(/\.srt/im)
							new_ligne = WebSub.new
							new_ligne.fichier = entry.to_s.strip
							new_ligne.date = rel.to_s
							new_ligne.lien = vers.to_s
							new_ligne.source = "SeriesSub"
							new_ligne.referer = monURL
							new_ligne
						end
					end
					# Cas du fichier srt simple
					############################
				elsif fichierCible.to_s.match(/srt/) && !fichierCible.to_s.match(/\.(VO|eng|en)\./im)
					new_ligne = WebSub.new
					new_ligne.fichier = fichierCible.to_s
					new_ligne.date = " "+rel.to_s+" "
					new_ligne.lien = vers.to_s
					new_ligne.source = "SeriesSub"
					new_ligne.referer = monURL
					new_ligne
				end
				# Cas du fichier zip de saison
				###############################
			elsif k.inner_html.match(/#{rec3}/im) && k.inner_html.match(/(vf|fr)/im)

				# Info globales au zip
				fichierCible = k.at("a.linkst").inner_html
				vers = k.at("a.linkst").attr("href").to_s.scan(/[0-9]*/)
				rel = k.at(".st_update").inner_html.to_s.gsub(/\//, '.').scan(/[0-9][0-9].[0-9][0-9].[0-9][0-9]/)

				if fichierCible.to_s.match(/zip/im)
					# Downlaod du zip
					req = "http://www.seriessub.com/download-#{vers}.html"
					path = FileCache.get_file(req, :referer => monURL, :zip => true)

					# Recherche dans le zip
					`zipinfo -1 #{path}`.collect do |entry|
						if entry.to_s.match(/#{rec4}|#{rec5}/im) && !entry.to_s.match(/(\.(VO|eng|en)\.|MACOSX)/im) && entry.to_s.match(/\.srt/im)
							new_ligne = WebSub.new
							new_ligne.fichier = entry.to_s.strip
							new_ligne.date = rel.to_s
							new_ligne.lien = vers.to_s
							new_ligne.referer = monURL
							new_ligne
						end
					end
				end
			end
		end
	end
end
