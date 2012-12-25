class Plugin::Addicted < Plugin::Base

	def get_from_source
		# generer le fichier /tmp/Subs.srt
		item = current.candidats[idx_candidat]
		FileCache.get_srt("http://www.addic7ed.com#{item.lien}", item.referer, true)
	end

	def do_search
		# faire l'analyse et la recherche d'un épisode spécifique
		monURL = "http://www.addic7ed.com/serie/#{current.serie.gsub(/ /, '%20')}/#{current.saison}/#{current.episode}/8"
		rec = sprintf("%s %dx%02d", current.serie, current.saison, current.episode)

		# Trouver la page de la serie :
		doc = FileCache.get_html(monURL)

		if doc.inner_text.match("Couldn't find any subs with the specified language. Filter ignored") then return end

		doc.search("div[@id='container95m'] table[@class='tabel95'] tr td table[@class='tabel95']").collect do |k|
			new_ligne = WebSub.new
			txt = [rec, '-']
			txt << k.at("td:nth-of-type(1)").text.to_s.squish.gsub(/\s*Version\s+/im, '').gsub(/[,].+$/, '').squish
			txt << '-'
			txt << k.search("td[@class='newsDate']").at("td:nth-of-type(1)").text.to_s.gsub(/works?\s+with/im, '').squish
			txt << ".srt"
			new_ligne.fichier = txt.join('-').gsub(/[-]{2,}/im, '-')
			new_ligne.date = k.at("td:nth-of-type(3)").text.to_s
			new_ligne.lien = k.at("a[@class='buttonDownload']")['href']
			new_ligne.referer = monURL
			new_ligne
		end

	end
end
