# Structure de gestion des sous titres trouvés (candidats)
class WebSub < CommonStruct
	attr_accessor :fichier, :date, :lien, :source, :referer
	attr_accessor :errors, :score, :confiant

	def initialize(*args)
		self.score = 12
		self.confiant = 0
		self.errors ||= {}
		super
	end

	def valid_serie?
		!errors[:serie]
	end

	def valid_saison?
		!errors[:saison]
	end

	def valid_episode?
		!errors[:episode]
	end

	def valid_team?
		!errors[:team]
	end

	def valid_info?
		!errors[:infos]
	end

	def calcul_confiance(ligne, rank = 0)
		return 0 if fichier.blank?

		self.errors = {}
		begin
			# Check du nom de la série
			unless fichier.match(%r{#{ligne.serie.gsub(/\s+/, '.+')}}i)
				self.score -= 3
				self.errors[:serie] = true
			end

			# Check du nom de la team
			# on verifie le nom complet, mais aussi les formes du type .3LETTRES. et .4LETTRES.
			unless fichier.match(%r{(#{ligne.team}|[\.-]#{ligne.team.to_s[0..3]}?[\.-])}i)
				# dim et lol sont le même groupe
				unless ligne.team.match(/^(dim|lol|dimension)$/i) && fichier.match(/(dim[\.-]|lol[\.-]|dimension)/i)
					self.score -=	 3
					self.errors[:team] = true
				end
			end

			# Check des infos supplémentaires, mais sans tenir compte de l'ordre qui peut varier
			ok = true
			ligne.infos.split(/\./).each do |key|
				next if key.blank?
				next if fichier.match(%r{\.#{key}}i)
				ok = false
				break
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
			if fichier.match(/tag/i) && !fichier.match(/notag/i)
				self.score += 1 # avec tag c'est mieux que sans tag
			end

			# check du format 720p
			if fichier.match(/720p/i)
				if ligne.format == '720p'
					self.score += 1
				elsif !self.errors[:team]
					# si pas le même format mais même team, alors c'est quand même mieux qu'une autre team
					self.score += 1
				end
			end

			self.confiant = (self.score.to_f / 4).round + rank
			self.score += rank

			if self.confiant >=3
				if self.errors.size>0
					self.confiant = 2 # on peut pas avoir totalement confiance s'il y a une erreur
				else
					self.confiant = 3
				end
			elsif self.confiant<1
				self.confiant = 1
			end
			return self.confiant
		rescue StandardError => e
			Tools.logger.error "# SubsMgr Error # calcul_confiance [#{ligne.fichier}] : #{e}\n#{e.backtrace.join("\n")}"
			ligne.comment = "Pb dans l'analyse du fichier"
			return 0
		end
	end

	# FIXME: il faut en cas d'egalité totale prendre le plus récent en premier
	# nécessite au préalable de repasser sur tous les parsing de date
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
		when txt.match(/s0?#{saison}e0?#{episode}([^0-9]|$)/i) then true # format S01E01 et variantes
		when txt.match(/0?#{saison}x0?#{episode}([^0-9]|$)/i) then true # format 01X01 et variantes
		when txt.match(/#{saison}#{sprintf('%02d',episode)}([^0-9]|$)/i) then true	 # format 101
		else false
		end
	end

	# verifie si le fichier name ressemble a un nom de fichier "français" (ie pas VO ou EN) et exploitable (srt/zip/rar)
	def self.french?(txt)
		return false unless txt.match(/\.(srt|rar|zip)$/i)
		return false if txt.match(/[\.\s_-](EN|VO)[\.\s_-]/i)
		return true
	end

end
