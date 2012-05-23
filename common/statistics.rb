# encoding: utf-8
module Statistics
	module_function
	def lignes_stats
		@lignesstats ||= []
	end

	def load
		@stats = Plist::parse_xml("#{Common::PREF_PATH}/SubsMgrStats.plist")
		@lignesstats = []

		Plugin::LIST.each do |source|
			new_ligne = Stats.new
			new_ligne.source = source
			if @stats && (data = @stats[source])
				new_ligne.search = data["Searched"]
				new_ligne.process = data["Processed"]
				new_ligne.TimeSearch = data["Stime"]
				new_ligne.TimeProcess = data["Ptime"]
				new_ligne.NbFound = data["Sfound"]
				new_ligne.TotalMarks = data["Smark"]
				new_ligne.NbAuto = data["Pauto"]
				new_ligne.image = Icones.list[source]
			end
			@lignesstats << new_ligne
		end
		@lignesstats
	end

	def save
		@stats ||= {}
		Plugin::LIST.each_with_index do |source, idx|
			@stats[source] ||= {}
			@stats[source]["Searched"] = @lignesstats[idx].search.to_i
			@stats[source]["Processed"] = @lignesstats[idx].process.to_f
			@stats[source]["Stime"] = @lignesstats[idx].TimeSearch.to_f
			@stats[source]["Ptime"] = @lignesstats[idx].TimeProcess.to_f
			@stats[source]["Sfound"] = @lignesstats[idx].NbFound.to_i
			@stats[source]["Smark"] = @lignesstats[idx].TotalMarks.to_f
			@stats[source]["Pauto"] = @lignesstats[idx].NbAuto.to_i
		end
		@stats.save_plist("#{Common::PREF_PATH}/SubsMgrStats.plist")
	end

	def update_stats_search(index, start, marks, count)
		@lignesstats[index].search = @lignesstats[index].search + 1
		@lignesstats[index].TotalMarks = @lignesstats[index].TotalMarks + marks
		@lignesstats[index].TimeSearch = @lignesstats[index].TimeSearch + Time.now.to_f - start.to_f
		if count > 0
			@lignesstats[index].NbFound += count
		end
		@lignesstats
	end

	def update_stats_accept(index, start, sender)
		@lignesstats[index].process = @lignesstats[index].process + 1
		@lignesstats[index].TimeProcess = @lignesstats[index].TimeProcess + Time.now.to_f - start.to_f
		if sender == @team
			@lignesstats[index].NbAuto = @lignesstats[index].NbAuto + 1
		end
		@lignesstats
	end

	def refresh
		processed = 0
		borne_sup = Plugin::LIST.size - 1
		for i in 0..borne_sup
			# Calculs
			next unless @lignesstats[i]
			if @lignesstats[i].search.to_f > 0
				@lignesstats[i].stime = sprintf("%.3f s",@lignesstats[i].TimeSearch.to_f / @lignesstats[i].search)
				@lignesstats[i].sfound = sprintf("%.2f",@lignesstats[i].NbFound.to_f / @lignesstats[i].search)
			end
			if @lignesstats[i].NbFound.to_f > 0
				@lignesstats[i].smark = sprintf("%.2f",@lignesstats[i].TotalMarks.to_f / @lignesstats[i].NbFound)
			end

			if @lignesstats[i].process.to_f > 0
				@lignesstats[i].ptime = sprintf("%.3f s",@lignesstats[i].TimeProcess.to_f / @lignesstats[i].process)
				@lignesstats[i].pauto = sprintf("%.1f %",@lignesstats[i].NbAuto.to_f * 100 / @lignesstats[i].process)
			end

			processed = processed + @lignesstats[i].process.to_f
		end

		if processed > 0
			for i in 0..borne_sup
				next unless @lignesstats[i] 
				@lignesstats[i].pratio = sprintf("%.1f %",@lignesstats[i].process.to_f * 100 / processed)
			end
		end
		@lignesstats
	end
end
