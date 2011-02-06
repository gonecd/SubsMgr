module Statistics
  module_function
  def lignes_stats
    @lignesstats ||= []
  end

  def load
    @stats = Plist::parse_xml("/Library/Application Support/SubsMgr/SubsMgrStats.plist")
    @lignesstats = []

    for i in Plugin::LIST
      new_ligne = Stats.new
      new_ligne.source = i
      new_ligne.search = @stats[i]["Searched"]
      new_ligne.process = @stats[i]["Processed"]
      new_ligne.TimeSearch = @stats[i]["Stime"]
      new_ligne.TimeProcess = @stats[i]["Ptime"]
      new_ligne.NbFound = @stats[i]["Sfound"]
      new_ligne.TotalMarks = @stats[i]["Smark"]
      new_ligne.NbAuto = @stats[i]["Pauto"]
      new_ligne.image = Icones.list[i]

      @lignesstats << new_ligne
    end
    @lignesstats
  end

  def save
    j = 0
    for i in Plugin::LIST
      @stats[i]["Searched"] = @lignesstats[j].search
      @stats[i]["Processed"] = @lignesstats[j].process
      @stats[i]["Stime"] = @lignesstats[j].TimeSearch
      @stats[i]["Ptime"] = @lignesstats[j].TimeProcess
      @stats[i]["Sfound"] = @lignesstats[j].NbFound
      @stats[i]["Smark"] = @lignesstats[j].TotalMarks
      @stats[i]["Pauto"] = @lignesstats[j].NbAuto
      j = j+1
    end
    @stats.save_plist("/Library/Application Support/SubsMgr/SubsMgrStats.plist")
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
    for i in 0..7
      # Calculs
      if @lignesstats[i].search > 0
        @lignesstats[i].stime = sprintf("%.3f s",@lignesstats[i].TimeSearch.to_f / @lignesstats[i].search)
        @lignesstats[i].sfound = sprintf("%.2f",@lignesstats[i].NbFound.to_f / @lignesstats[i].search)
      end
      if @lignesstats[i].NbFound > 0
        @lignesstats[i].smark = sprintf("%.2f",@lignesstats[i].TotalMarks.to_f / @lignesstats[i].NbFound)
      end

      if @lignesstats[i].process > 0
        @lignesstats[i].ptime = sprintf("%.3f s",@lignesstats[i].TimeProcess.to_f / @lignesstats[i].process)
        @lignesstats[i].pauto = sprintf("%.1f %",@lignesstats[i].NbAuto.to_f * 100 / @lignesstats[i].process)
      end

      processed = processed + @lignesstats[i].process
    end

    if processed > 0
      for i in 0..7
        @lignesstats[i].pratio = sprintf("%.1f %",@lignesstats[i].process.to_f * 100 / processed)
      end
    end
    @lignesstats
  end
end
