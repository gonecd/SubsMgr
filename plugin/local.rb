class Plugin::Local < Plugin::Base
	ICONE = 'dir.png'
	@@local_path = nil

	def self.local_path
		@@local_path
	end

	def self.local_path=(new_value)
		@@local_path = new_value
	end

	def get_from_source
		item = current.candidats[idx_candidat]
		FileUtils.cp(File.join(self.class.local_path, item.fichier), "/tmp/Sub.srt")
	end

	def do_search
		return unless File.exist?(self.class.local_path)

		monPattern1 = sprintf("%s.%d%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)
		monPattern2 = sprintf("%s.S%02dE%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)
		monPattern3 = sprintf("%s.s%02de%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)
		monPattern4 = sprintf("%s - %dx%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)
		monPattern5 = sprintf("%s.%dx%02d", current.serie.downcase.gsub(/ /, '.'), current.saison, current.episode)

		Dir.foreach(self.class.local_path).collect do |file|
			next unless file.match(/srt/im)
			if file.match(/#{monPattern1}|#{monPattern2}|#{monPattern3}|#{monPattern4}|#{monPattern5}/im)
				new_ligne = WebSub.new
				new_ligne.fichier = file
				new_ligne.date = File.mtime(File.join(self.class.local_path, file)).strftime("%d.%m.%Y")
				new_ligne.lien = "Local"
				new_ligne.referer = ""
				new_ligne
			end
		end
	end
end
