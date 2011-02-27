module Plugin
	LIST = ["Forom", "Podnapisi", "SeriesSub", "SousTitresEU", "TVSubs", "TVSubtitles", "Local", "MySource"]

	def constantize(kls)
		if kls != '' && const_defined?(kls)
			Plugin.const_get(kls)
		end
	end
	module_function :constantize


	class Base
		attr_accessor :current, :rank, :idx_candidat

		def get_from_source
			# Récupérer le sous titre et le mettre dans /tmp/Sub.srt
			#
			# Fonctions utiles :
			#		FileCache.get_srt(lien, referer = nil) -- stocke le srt disponible sur lien dans /tmp/Sub.srt
			#		FileCache.get_zip(lien, fichier, referer = nil) -- fichier étant le fichier à extraire du zip, la cible étant automatiquement /tmp/Sub.srt
		end

		# must be overloaded
		def do_search
			# doit retourner un tableau de lignes du type (les autres champs nécessaires sont remplis automatiquement)
			#		 new_ligne = WebSub.new
			#		 new_ligne.fichier = ""
			#		 new_ligne.date = ""
			#		 new_ligne.lien = ""
			#		 new_ligne.referer = ""
			[]
		end

		# ----------------------------
		# NOTHING TO CHANGE AFTER THIS
		# ----------------------------
		def initialize(current, rank, idx_candidat)
			self.current = current
			self.current.candidats ||= []
			self.rank = rank.to_f / 1000
			self.idx_candidat = idx_candidat
		end

		# generic search
		def search_sub
			# Lister tous les candidats disponibles et remplir la structure @current.candidats
			start = Time.now
			count = marks = 0
			begin
				kls = self.class.name.split(':').last
				# la liste de resultats peut contenir des valeurs nil ainsi que des tableaux imbriqués
				# donc on remet tout à plat, on purge les nil, et on ajoute tout ce qui est commun
				# a toutes les entrées plutot que de le faire au moment du parsing (cela donne du code
				# un peu plus "basique" pour les plugins)
				list = (do_search || []).flatten.compact.collect do |item|
					item.confiant = get_confiance(item.fichier.downcase)
					item.source = kls
					item
				end
				count = list.size
				marks = list.inject(0) { |sum, e| sum += e.confiant.to_f}
				self.current.candidats = self.current.candidats.concat(list)
			rescue Exception => e
				Tools.logger.error "# SubsMgr Error # search_sub #{self.class.name} [#{current.fichier}]: #{e.inspect}\n#{e.backtrace.join("\n")}"
				self.current.comment = "Pb dans le parsing #{self.class.name}"
			end
			self.current.send("#{self.class::NAME}=", count)
			# Mise à jour des stats
			# FIXME: remettre en place une fonction independante de l'UI
			Statistics.update_stats_search(self.class::INDEX, start, marks, count) if count > -1
		end

		def self.calcul_confiance(sousTitre, current)
			errors = {}
			begin
				maConfiance = 3

				# Check du nom de la série
				unless sousTitre.match(%r{#{current.serie.gsub(/\s+/, '.+')}}i)
					maConfiance -= 2
					errors[:serie] = true
				end

				# Check du nom de la team
				# on verifie le nom complet, mais aussi les formes du type .3LETTRES. et .4LETTRES.
				unless sousTitre.match(%r{(#{current.team}|[\.-]#{current.team.to_s[0..3]}?[\.-])}i)
					maConfiance -=	2
					errors[:team] = true
				end

				# Check des infos supplémentaires, mais sans tenir compte de l'ordre qui peut varier
				ok = true
				current.infos.split(/\./).each do |key|
					if key != '' && !sousTitre.match(%r{\.#{key}}i)
						ok = false
						break
					end
				end
				unless ok
					maConfiance -= 1
					errors[:infos] = true
				end

				# Check de la saison et l'épisode
				unless valid_episode?(sousTitre, current.saison, current.episode)
					maConfiance -= 2
					errors[:saison] = true
					errors[:episode] = true
				end

				# on préfère les version tag vs notag
				if sousTitre.match(/tag/im) && !sousTitre.match(/notag/im)
					maConfiance += 0.1
				end

				if (maConfiance<1) and (sousTitre != "")
					maConfiance = 1
				end

				return [maConfiance, errors]

			rescue Exception => e
				Tools.logger.error "# SubsMgr Error # calcul_confiance [#{current.fichier}] : #{e}\n#{e.backtrace.join("\n")}"
				current.comment = "Pb dans l'analyse du fichier"
				return [0, errors]
			end
		end

		# on verifie si +txt+ est une chaine qui correspond à l'épisode +episode+ de la saison +saison+
		def self.valid_episode?(txt, saison, episode)
			txt = txt.to_s.strip
			return false if txt.blank?
			return false unless txt.match(/\.srt/im)
			return false if txt.match(/\.(EN|VO)\./im)

			case
			when txt.match(/s0?#{saison}e0?#{episode}/im): true # format S01E01 et variantes
			when txt.match(/0?#{saison}x0?#{episode}/im): true # format 01X01 et variantes
			when txt.match(/#{saison}#{sprintf('%02d',episode)}/im): true		# format 101
			else false
			end
		end


		protected

		def get_confiance(sousTitre)
			(val, foo) = self.class.calcul_confiance(sousTitre, self.current)
			val.to_f + self.rank
		end

	end
end
