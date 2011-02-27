# ------------------------------------------
# Structures de gestion
# ------------------------------------------

class CommonStruct
	# on met en place la possibilité d'initialiser une structure via
	# Structure.new(:key1 => val1, :key2 => val2, ...)
	def initialize(options = {})
		options.each do |k,v|
			self.send("#{k}=", v) if self.respond_to?(k)
		end
	end
end

# ------------------------------------------
# Structures de gestion
# ------------------------------------------


# Structure d'insertion dans la liste
class Ligne < CommonStruct
	attr_accessor :fichier, :date, :conf, :comment
	attr_accessor :serie, :saison, :episode, :team, :format, :source, :provider, :titre, :infos
	attr_accessor :repTarget, :fileTarget
	attr_accessor :forom, :seriessub, :podnapisi, :tvsubs, :tvsubtitles, :local, :mysource, :soustitreseu
	attr_accessor :status, :candidats
	
	def to_s
		"<Ligne serie:#{serie} - saison: #{saison} - episode: #{episode} - team:#{team} - format: #{format}>"
	end
end

# Structure de gestion des sous titres trouvés (candidats)
class WebSub < CommonStruct
	attr_accessor :fichier, :date, :lien, :source, :referer
	attr_accessor :errors, :score, :confiant

	def calcul_confiance(ligne, rank = 0)
		return 0 if fichier.blank?
		
		self.errors = {}
		begin
			self.score = 12

			# Check du nom de la série
			unless fichier.match(%r{#{ligne.serie.gsub(/\s+/, '.+')}}i)
				self.score -= 3
				self.errors[:serie] = true
			end

			# Check du nom de la team
			# on verifie le nom complet, mais aussi les formes du type .3LETTRES. et .4LETTRES.
			unless fichier.match(%r{(#{ligne.team}|[\.-]#{ligne.team.to_s[0..3]}?[\.-])}i)
				self.score -=	 3
				self.errors[:team] = true
			end

			# Check des infos supplémentaires, mais sans tenir compte de l'ordre qui peut varier
			ok = true
			ligne.infos.split(/\./).each do |key|
				if key != '' && !fichier.match(%r{\.#{key}}i)
					ok = false
					break
				end
			end
			unless ok
				self.score -= 3
				self.errors[:infos] = true
			end

			# Check de la saison et l'épisode
			unless WebSub.valid_episode?(fichier, ligne.saison, ligne.episode)
				self.score -= 3
				self.errors[:saison] = true
				self.errors[:episode] = true
			end

			# on préfère les version tag vs notag
			if fichier.match(/tag/im) && !fichier.match(/notag/im)
				self.score += 1 # avec tag c'est mieux que sans tag
			end

			# check du format 720p
			if fichier.match(/720p/im) && ligne.format == '720p'
				self.score += 1
			end
			
			self.confiant = (self.score.to_f / 4).round
			if self.confiant >=12 && self.errors.size>0
				self.confiant = 8 # on peut pas avoir totalement confiance s'il y a une erreur
			elsif self.confiant<1
				self.confiant = 1
			end
			self.confiant += rank
			self.score += rank
			return self.confiant
		rescue StandardError => e
			Tools.logger.error "# SubsMgr Error # calcul_confiance [#{ligne.fichier}] : #{e}\n#{e.backtrace.join("\n")}"
			ligne.comment = "Pb dans l'analyse du fichier"
			return 0
		end
	end

	def <=>(other)
		# meilleure confiance en premier
		result = (other.score <=> self.score)
		
		# en cas d'egalite, celui qui a le moins d'erreurs gagne
		result = (self.errors.size <=> other.errors.size) if result == 0
		result
	end
	
	def to_s
		"<WebSub fichier:{fichier} - date:#{date} - lien:#{lien} - confiant:#{confiant}>"
	end

	# on verifie si +txt+ est une chaine qui correspond à l'épisode +episode+ de la saison +saison+
	def self.valid_episode?(txt, saison, episode)
		txt = txt.to_s.strip
		return false if txt.blank?
		return false unless french?(txt)

		case
		when txt.match(/s0?#{saison}e0?#{episode}([^0-9]|$)/im): true # format S01E01 et variantes
		when txt.match(/0?#{saison}x0?#{episode}([^0-9]|$)/im): true # format 01X01 et variantes
		when txt.match(/#{saison}#{sprintf('%02d',episode)}([^0-9]|$)/im): true		# format 101
		else false
		end
	end
	
	# verifie si le fichier name ressemble a un nom de fichier "français" (ie pas VO ou EN) et exploitable (srt/zip/rar)
	def self.french?(txt)
		return false unless txt.match(/\.(srt|rar|zip)$/im)
		return false if txt.match(/[\.\s_-](EN|VO)[\.\s_-]/im)
		return true
	end
	
end

# Structure d'insertion dans la liste des séries
class Series < CommonStruct
	attr_accessor :nom, :image, :idtvdb
	
	def to_s
		"<Series nom:#{nom} - image:#{idtvdb}>"
	end
end

# Structure d'insertion dans la Librairie
class Library < CommonStruct
	attr_accessor :serie, :saison, :status, :URLTVdb, :nbepisodes, :image, :episodes

	def to_s
		"<Library serie:#{serie} - saison:#{saison} - status:#{status} - nbepisodes:#{nbepisodes}>"
	end
end

# Structure d'insertion dans les stats
class Stats < CommonStruct
	attr_accessor :source, :image, :search, :stime, :sfound, :smark, :process, :ptime, :pratio, :pauto
	attr_accessor :TimeSearch, :TimeProcess, :NbFound, :TotalMarks, :NbAuto
end

# Structure d'insertion dans les sources
class Sources < CommonStruct
	attr_accessor :source, :image, :active, :rank

	def to_s
		"<Sources source:#{source} - active:#{active} - rank:#{rank}>"
	end
end

# Structure de gestion pour les infos d'une saison
class InfosSaison < CommonStruct
	attr_accessor :episode, :titre, :diffusion, :telecharge, :soustitre
	
	def to_s
		"<InfosSaison episode:#{episode} - titre:#{titre} - diffusion:#{diffusion}>"
	end
end


class Hash

	def deep_merge(hash)
		target = dup

		hash.keys.each do |key|
			if hash[key].is_a? Hash and self[key].is_a? Hash
				target[key] = target[key].deep_merge(hash[key])
				next
			end

			target[key] = hash[key]
		end

		target
	end

end
