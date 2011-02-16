#
#  SubsMgr.rb
#  SubsMgr
#
#  Created by Cyril DELAMARE on 31/01/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

$LOAD_PATH << File.join(File.dirname(__FILE__), "common")
$LOAD_PATH << File.join(File.dirname(__FILE__), "plugin")

require 'osx/cocoa'
require 'common'

class SubsMgr < OSX::NSWindowController
  # ------------------------------------------
  # Pointeurs sur les objets de l'IHM
  # ------------------------------------------

  ib_outlets :serie, :saison, :episode, :team, :infos, :liste, :listeseries, :image, :fileTarg, :repTarg
  ib_outlets :subs, :release, :subsNb, :subsTot, :roue, :barre, :confiance, :plusmoins, :source
  ib_outlets :bFiltre, :listestats, :bSupprCrochets, :bSupprAccolades, :bCommande
  ib_outlets :source1, :source2, :source3

  # Petits drapeaux d'erreurs
  ib_outlets :errSaison, :errEpisode, :errTeam, :errInfos, :errSerie

  # Ecran Préférences
  ib_outlets :pDirTorrent, :pDirSerie, :pDirBanner, :pDirSubs, :pDirTorrents, :pDirTorrentButton, :pDirSerieButton, :pDirBannerButton, :pDirSubsButton, :pDirTorrentsButton
  ib_outlets :pFileRule, :pDirRule, :pSepRule
  ib_outlets :pConfiance, :pSchedSearch, :pSchedProcess, :pForomKey
  ib_outlets :listesources, :nomSource, :rankSource, :activeSource, :alertMessage
  ib_outlets :pMove, :pSupprCrochets, :pSupprAccolades, :pCommande

  # Fenêtres annexes
  ib_outlets :fenPref, :fenMain, :fenMovie, :fenStats, :fenInfos, :fenWait, :fenSource
  ib_outlets :cinema
  ib_outlets :ovliste, :ovimage, :ovcharge, :ovsubs
  ib_outlets :libSeries
  ib_outlets :vue

  # Boutons Live et Historiques
  ib_outlets :bSearch, :bTest, :bAccept, :bClean, :bRollback, :bGoWeb, :bLoadSub, :bViewSub, :bManual
  ib_outlets :bCleanSerie, :bWebSerie

  # Filtres de la liste
  ib_outlets :bAll, :bAttente, :bTraites, :bErreurs

  # ------------------------------------------
  # Méthode d'initialisation
  # ------------------------------------------
  def awakeFromNib

    # Gestion des fenêtres
    @fenWait.makeKeyAndOrderFront_(self)

    # Initialisation des variables globales
    @allEpisodes = []
    @lignes = []
    @lignesseries = []
    @lignesinfos = []
    @lignessources = []
    @ligneslibrary = []
    @liste.dataSource = self
    @ovliste.dataSource = self
    @listeseries.dataSource = self
    @listestats.dataSource = self
    @listesources.dataSource = self
    @serieSelectionnee = "."
    @spotFilter = ""
    @appPath = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
    Icones.path = File.join(@appPath, "Icones")

    # First run ? Fichier manquants ?
    unless File.exist?("/Library/Application\ Support/SubsMgr/")
      FileUtils.makedirs("/Library/Application\ Support/SubsMgr/")
    end
    unless File.exist?("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv")
      FileUtils.touch("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv")
    end
    unless File.exist?("/Library/Application\ Support/SubsMgr/SubsMgrPrefs.plist")
      FileUtils.cp(File.join(@appPath, "SubsMgrPrefs.plist"), "/Library/Application\ Support/SubsMgr/SubsMgrPrefs.plist")
    end

    # Initialisations des sources dans la fenêtre de préférences
    for i in Plugin::LIST
      new_ligne = Sources.new
      new_ligne.source = i
      new_ligne.image = Icones.list[i]
      @lignessources << new_ligne
    end
    @listesources.reloadData
    PrefCancel(self)

    # Initialisations spécifiques pour les plugins
    Plugin::Forom.forom_key = @pForomKey.stringValue().to_s
    Plugin::Local.local_path = @pDirSubs.stringValue().to_s

    # Initialisation des Statistiques
    StatsRAZ(self) unless File.exist?("/Library/Application\ Support/SubsMgr/SubsMgrStats.plist")
    StatsLoad()
    StatsRefresh(self)

    # Construction des listes de series et d'episodes
    RelisterEpisodes()
    RelisterSeries()
    RelisterInfos()
    RaffraichirListe()
    @fenWait.close()
  end


  def CheckForUdate()
  end

  def ShowReleaseNotes()
  end


  # ------------------------------------------
  # Fonctions de gestion du tableau
  # ------------------------------------------
  def rowSelected
    @current = @lignes[@liste.selectedRow()]

    begin
      clearResults()

      # Affichage de l'analyse du fichier source
      @serie.setStringValue_(@current.serie)
      @image.setImage(SerieBanner(@current.serie))
      @saison.setIntValue(@current.saison)
      @episode.setIntValue(@current.episode)
      @team.setStringValue_(@current.team)
      @infos.setStringValue_(@current.infos)

      # Construire les fichiers et répertoire Targets
      @repTarg.setStringValue(@current.repTarget)
      @fileTarg.setStringValue(@current.fileTarget)

      # Gestion de l'affichage des boutons
      if @current.status == "Traité"
        @bRollback.setHidden(false)
        @bClean.setHidden(false)
      else                      # Episode en attente
        @bSearch.setHidden(false)
        @bAccept.setHidden(false)
        @bTest.setHidden(false)
        @bLoadSub.setHidden(false)
        @bGoWeb.setHidden(false)
        @bManual.setHidden(false)
        @bViewSub.setHidden(false)
      end

      # On se posionne sur le meilleur sous titre trouvé
      if @current.candidats.size() != 0
        bestConf = @current.candidats[0].confiant
        bestcandidat = 0
        for i in (0..@current.candidats.size()-1)
          if @current.candidats[i].confiant > bestConf
            bestcandidat = i
            bestConf = @current.candidats[i].confiant
          end
        end
        @subsTot.setIntValue_(@current.candidats.size())
        @subsNb.setIntValue_(@current.candidats.size())
        @plusmoins.setIntValue(bestcandidat+1)
        ChangeInstance(self)
      end


    rescue Exception=>e
      puts "# SubsMgr Error # rowSelected ["+@current.fichier+"] : "+e
      @current.comment = "Pb dans l'analyse du fichier"
    end

    @liste.reloadData
  end
  ib_action :rowSelected

  def serieSelected(sender)

    selectedLigne = @listeseries.selectedRow()
    @serieSelectionnee = @ligneslibrary[selectedLigne].serie
    @saisonSelectionnee = @ligneslibrary[selectedLigne].saison
    @URLTVdb = @ligneslibrary[selectedLigne].URLTVdb
    RaffraichirListe()
    @image.setImage(@ligneslibrary[selectedLigne].image)

  end
  ib_action :serieSelected

  def filterSelected(sender)

    @bAll.setState_(false)
    @bAttente.setState_(false)
    @bErreurs.setState_(false)
    @bTraites.setState_(false)

    sender.setState_(true)

    #Relister(sender)
    RaffraichirListe()

  end
  ib_action :filterSelected

  def spotlightSelected(sender)
    @spotFilter = @bFiltre.stringValue().to_s
    RaffraichirListe()
  end
  ib_action :spotlightSelected


  def numberOfRowsInTableView(view)
    case view.description
    when @liste.description: @lignes.size
    when @listeseries.description: @ligneslibrary.size
    when @listestats.description: Statistics.lignes_stats.size
    when @ovliste.description: @lignesinfos.size
    when @listesources.description: @lignessources.size
    else
      $stderr.puts "Attention : view non identifiée dans numberOfRowsInTableView #{view.description}"
      @lignes.size
    end
  end

  def tableView_objectValueForTableColumn_row(view, column, index)
    case view.description
    when @liste.description
      ligne = @lignes[index]
      case column.identifier
      when 'Message': ligne.comment
      when 'Confiance': ligne.conf
      when 'None': "-"
      else
        field = column.identifier.downcase
        ligne.send(field) if ligne.respond_to?(field)
      end
    when @listeseries.description
      ligne = @ligneslibrary[index]
      case column.identifier
      when 'serie': ligne.image
      when /ep[0-9]+/im : ligne.espisodes(column.identifier.gsub(/ep/im, '').to_i)
      else
        field = column.identifier.downcase
        ligne.send(field) if ligne.respond_to?(field)
      end
    when @listestats.description
      ligne = Statistics.lignes_stats[index]
      field = column.identifier.downcase
      ligne.send(field) if ligne.respond_to?(field)
    when @ovliste.description
      ligne = @lignesinfos[index]
      field = column.identifier.downcase
      ligne.send(field) if ligne.respond_to?(field)
    when @listesources.description
      ligne = @lignessources[index]
      case column.identifier
      when 'Ranking': ligne.rank
      else
        field = column.identifier.downcase
        ligne.send(field) if ligne.respond_to?(field)
      end
    else
      puts "Attention : view non identifiée dans tableView_objectValueForTableColumn_row #{view.description}"
      nil
    end
  end

  def Relister (sender)
    # Construction des listes de series et d'episodes
    RelisterEpisodes()
    RelisterSeries()
    RaffraichirListe()
  end
  ib_action :Relister

  def RelisterEpisodes
    # Vider la liste
    @allEpisodes.clear

    # Récupération des fichiers en attente de traitement
    if File.exist?(@pDirTorrent.stringValue().to_s)
      Dir.chdir(@pDirTorrent.stringValue().to_s)
      Dir.glob("*.{avi,mkv,mp4,m4v}").each do |x|
        new_ligne = Ligne.new
        new_ligne.fichier = x
        new_ligne.date = File.mtime(x)
        new_ligne.conf = 0
        new_ligne.comment = ""
        new_ligne.status = "Attente"
        new_ligne.candidats = []
        @allEpisodes << new_ligne

        # Mise à jour des infos calculées
        @current = new_ligne
        AnalyseFichier(@current.fichier)
        buildTargets()
      end
    end

    # Récupération des fichiers traités
    File.open("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv").each do |line|
      begin
        row = CSV.parse_line(line,';')
        raise CSV::IllegalFormatError unless (row && row.size == 8)
        new_ligne = Ligne.new
        new_ligne.fichier = row[3]
        new_ligne.date = row[5]
        new_ligne.conf = 0
        new_ligne.status = "Traité"
        new_ligne.comment = "Traité en "+row[6].to_s+" sur "+row[7].to_s

        new_ligne.candidats = []
        new_candid = WebSub.new
        new_candid.fichier = row[4]
        new_candid.date = row[6]
        new_candid.lien = row[5]
        new_candid.confiant = 0
        new_candid.source = row[7]
        new_candid.referer = "None"
        new_ligne.candidats << new_candid

        @allEpisodes << new_ligne

        # Mise à jour des infos calculées
        @current = new_ligne
        AnalyseFichier(@current.fichier)
        buildTargets()
        @current.candidats[0].confiant = CalculeConfiance(@current.candidats[0].fichier.downcase)
        @current.conf = @current.candidats[0].confiant
      rescue CSV::IllegalFormatError => err
        $stderr.puts "# SubsMgr Error # Invalid CSV history line skipped:\n#{line}"
      end
    end

    @allEpisodes.sort! {|x,y| x.fichier <=> y.fichier }
  end

  def RelisterSeries
    totalEpisodes = @allEpisodes.size
    @lignesseries.clear

    # Image pour le "All series" dans la liste de droite
    new_ligne = Series.new
    new_ligne.image = OSX::NSImage.alloc.initWithContentsOfFile_(@pDirBanner.stringValue()+"00 - All series.jpg")
    new_ligne.nom = "."
    @lignesseries << new_ligne


    # Mise à jour de la liste des series
    @allEpisodes.each do |episode|
      # La série est-elle déjà listée ?
      dejaListee = @lignesseries.any? do |serie|
        val = episode.serie.to_s
        (val == "Error") or (serie.nom == val.downcase)
      end

      # Ajout de la série dans la liste
      unless dejaListee
        temp = episode.serie.to_s.downcase
        imageFile = ""
        new_ligne = Series.new

        # Recherche d'une bannière en local
        Dir.chdir(@pDirBanner.stringValue().to_s)
        Dir[temp+"-*.jpg"].each do |x|
          imageFile = @pDirBanner.stringValue().to_s+x
          new_ligne.idtvdb = x.scan(/.*-([0-9]*).jpg/)[0][0]
        end

        # Recherche de la série sur theTVdb
        if imageFile == ""
          begin
            monURL = "http://www.thetvdb.com/api/GetSeries.php?seriesname="+temp.gsub(/ /, '+')
            doc = FileCache.get_html(monURL, :xml => true)
            monindex = 0
            compteur = 0
            doc.search("SeriesName").each do |k|
              if k.inner_html.downcase.to_s == temp.downcase.to_s then monindex = compteur end
              compteur = compteur + 1
            end
            compteur = 0
            doc.search("seriesid").each do |k|
              if compteur == monindex then new_ligne.idtvdb = k.inner_html.to_s end
              compteur = compteur + 1
            end
            if compteur == 0
              imageFile = ""
            else
              imageFile = @pDirBanner.stringValue().to_s+temp+"-"+new_ligne.idtvdb+".jpg"
            end

          rescue Exception=>e
            puts "#### RelisterSeries : Pb d'accès à theTVdb"
            puts "       Pour "+temp
            puts "       "+e
          end
        end

        # Récupération de la banière (locale ou sur tvdb)
        if File.exist?(imageFile)
          new_ligne.image = OSX::NSImage.alloc.initWithContentsOfFile_(imageFile)
        else
          monURL = ""
          compteur = 0
          doc.search("//banner").each do |k|
            if compteur == monindex then monURL = "http://www.thetvdb.com/banners/"+k.inner_html.to_s end
            compteur = compteur + 1
          end
          if monURL == ""
            new_ligne.image = OSX::NSImage.alloc.initWithContentsOfFile_(@pDirBanner.stringValue()+"00 - All series.jpg")
          else
            imageFile = FileCache.get_file(monURL, imageFile)
            new_ligne.image = OSX::NSImage.alloc.initWithContentsOfFile_(imageFile)
          end
        end
        new_ligne.nom = temp
        @lignesseries << new_ligne
      end
    end
    @lignesseries.sort! {|x,y| x.nom <=> y.nom }
    @listeseries.reloadData()
  end
  def RelisterInfos()
    @ligneslibrary.clear

    new_ligne = Library.new
    new_ligne.image = OSX::NSImage.alloc.initWithContentsOfFile_(@pDirBanner.stringValue()+"00 - All series.jpg")
    new_ligne.serie = "."
    new_ligne.saison = ""
    new_ligne.URLTVdb = "http://www.thetvdb.com/"
    new_ligne.nbepisodes = ""
    new_ligne.episodes = []
    @ligneslibrary << new_ligne

    @allEpisodes.each do |episode|
      # La série est-elle déjà listée ?
      dejaListee = @ligneslibrary.any? do |libitem|
        (episode.serie.to_s == "Error") or ( (libitem.serie == episode.serie.to_s.downcase) and (libitem.saison == episode.saison) )
      end

      # Ajout de la série dans la liste
      unless dejaListee
        new_ligne = Library.new
        new_ligne.serie = episode.serie.to_s.downcase
        new_ligne.saison = episode.saison
        new_ligne.image = SerieBanner(episode.serie)

        #        # Recherche de la page de la saison sur TheTVdb
        #        monURL = "http://www.thetvdb.com/?tab=series&id="+SerieId(episode.serie.to_s.downcase).to_s
        #
        #        doc = FileCache.get_html(monURL)
        #        doc.search("a.seasonlink").each do |k|
        #          if k.text.to_s == episode.saison.to_s
        #            monURL = "http://www.thetvdb.com"+k[:href].to_s
        #            new_ligne.URLTVdb = monURL
        #          end
        #        end
        #
        #        # Lecture des épisodes
        #        tableau = []
        #        index = 0
        #        doc = FileCache.get_html(monURL)
        #        doc.search("table#listtable tr").each do |k|
        #          k.search("td.odd,td.even").each do |k2|
        #          #k.search("td.odd,td.even,td.special").each do |k2|
        #            tableau[index]=k2.text.to_s
        #            index = index + 1
        #          end
        #        end
        #
        #        new_ligne.firstep = tableau[6].to_s.gsub(/-/, ' ')
        #        new_ligne.lastep = tableau[(index-1)-1].to_s.gsub(/-/, ' ')
        #        new_ligne.nbepisodes = 0
        #        new_ligne.status = Icones.list["Subtitled"]
        #        new_ligne.episodes = []
        #
        #        # Affichage des status par épisode
        #        for i in (1..(index-1)/4)
        #          begin
        #            if tableau[i*4].to_s == "Special"
        #              #new_ligne.episodes[i]=Icones.list["EpSpecial"]
        #            else
        #              if Date.parse(tableau[(i*4)+2]) < Date.today()
        #                new_ligne.nbepisodes = new_ligne.nbepisodes + 1
        #                new_ligne.episodes[new_ligne.nbepisodes]=Icones.list["Aired"]
        #
        #                subtitled = @allEpisodes.any? do |eps|
        #                  (eps.serie.downcase.to_s == new_ligne.serie) and (eps.saison == new_ligne.saison) and (eps.episode == new_ligne.nbepisodes) and (eps.status == "Traité")
        #                end
        #
        #                vidloaded = @allEpisodes.any? do |eps|
        #                  (eps.serie.downcase.to_s == new_ligne.serie) and (eps.saison == new_ligne.saison) and (eps.episode == new_ligne.nbepisodes) and (eps.status != "Traité")
        #                end
        #
        #                if subtitled
        #                  new_ligne.episodes[new_ligne.nbepisodes]=Icones.list["Subtitled"]
        #                else
        #                  if vidloaded
        #                    new_ligne.episodes[new_ligne.nbepisodes]=Icones.list["VideoLoaded"]
        #                    if new_ligne.status == Icones.list["Subtitled"] then new_ligne.status = Icones.list["VideoLoaded"] end
        #                  else
        #                    Dir.foreach(@prefs["Directories"]["Torrents"].to_s) do |file|
        #                      monPattern1 = sprintf("%s — %02dx%02d", new_ligne.serie, new_ligne.saison, new_ligne.nbepisodes)
        #                      monPattern2 = sprintf("%s — %dx%d", new_ligne.serie, new_ligne.saison, new_ligne.nbepisodes)
        #                      if ( file.downcase.match(monPattern1) or file.downcase.match(monPattern2) )
        #                        new_ligne.episodes[new_ligne.nbepisodes]=Icones.list["TorrentLoaded"]
        #                        if new_ligne.status == Icones.list["Subtitled"] or new_ligne.status == Icones.list["VideoLoaded"] then new_ligne.status = Icones.list["TorrentLoaded"] end
        #                      end
        #                    end
        #                  end
        #                end
        #              else
        #                new_ligne.nbepisodes = new_ligne.nbepisodes + 1
        #                new_ligne.episodes[new_ligne.nbepisodes]=Icones.list["NotAired"]
        #              end
        #            end
        #
        #            # Mise à jour du status gobal de la saison
        #            if new_ligne.episodes[new_ligne.nbepisodes] == Icones.list["VideoLoaded"] and new_ligne.status == Icones.list["Subtitled"] then new_ligne.status = Icones.list["VideoLoaded"] end
        #            if new_ligne.episodes[new_ligne.nbepisodes] == Icones.list["TorrentLoaded"] and (new_ligne.status == Icones.list["Subtitled"] or new_ligne.status == Icones.list["VideoLoaded"]) then new_ligne.status = Icones.list["TorrentLoaded"] end
        #            if new_ligne.episodes[new_ligne.nbepisodes] == Icones.list["NotAired"] then new_ligne.status = Icones.list["NotAired"] end
        #            if new_ligne.episodes[new_ligne.nbepisodes] == Icones.list["Aired"] and ( new_ligne.status == Icones.list["Subtitled"] or new_ligne.status == Icones.list["VideoLoaded"] or new_ligne.status == Icones.list["TorrentLoaded"] ) then new_ligne.status = Icones.list["Aired"] end
        #
        #
        #          rescue Exception=>e
        #            new_ligne.nbepisodes = new_ligne.nbepisodes + 1
        #            new_ligne.episodes[new_ligne.nbepisodes]=Icones.list["NotAired"]
        #          end
        #        end
        @ligneslibrary << new_ligne

      end
    end
    @ligneslibrary.sort! {|x,y| x.serie+x.saison.to_s <=> y.serie+y.saison.to_s }
    @listeseries.reloadData()
  end
  def RaffraichirListe

    @lignes.clear
    clearResults

    totalEpisodes = @allEpisodes.size
    for i in (0..totalEpisodes-1)
      episode = @allEpisodes[i]

      if @serieSelectionnee == "."
        if episode.fichier.to_s.downcase.match(@spotFilter.downcase)
          if (@bAll.state == 1)
            @lignes << episode
          elsif (@bTraites.state == 1) and (episode.status == "Traité")
            @lignes << episode
          elsif (@bAttente.state == 1) and (episode.status == "Attente")
            @lignes << episode
          elsif (@bErreurs.state == 1) and (episode.status != "Traité") and (episode.comment != "")
            @lignes << episode
          end
        end
      else
        if episode.fichier.to_s.downcase.match(@serieSelectionnee.gsub(/ /, '.')) and episode.fichier.to_s.downcase.match(@spotFilter.downcase) and episode.saison == @saisonSelectionnee
          if (@bAll.state == 1)
            @lignes << episode
          elsif (@bTraites.state == 1) and (episode.status == "Traité")
            @lignes << episode
          elsif (@bAttente.state == 1) and (episode.status == "Attente")
            @lignes << episode
          elsif (@bErreurs.state == 1) and (episode.status != "Traité") and (episode.comment != "")
            @lignes << episode
          end
        end
      end

    end

    @liste.reloadData()
  end

  def clearResults()
    # Masquer les boutons
    @bSearch.setHidden(true)
    @bAccept.setHidden(true)
    @bTest.setHidden(true)
    @bRollback.setHidden(true)
    @bClean.setHidden(true)
    @bLoadSub.setHidden(true)
    @bGoWeb.setHidden(true)
    @bManual.setHidden(true)
    @bViewSub.setHidden(true)

    # Vider les champs
    @release.setStringValue_("")
    @subs.setStringValue_("")
    @subsTot.setIntValue_(0)
    @subsNb.setIntValue_(0)
    @plusmoins.setIntValue(0)
    @serie.setStringValue_("")
    @saison.setStringValue_("")
    @episode.setStringValue_("")
    @team.setStringValue_("")
    @source.setStringValue_("")
    @infos.setStringValue_("")
    @fileTarg.setStringValue_("")
    @repTarg.setStringValue_("")
    @confiance.setIntValue(0)
    @image.setImage(@lignesseries[0].image)
  end
  def buildTargets()
    begin
      # Définition du répertoire cible
      case @pDirRule.selectedRow()
      when 0 then @current.repTarget = @pDirSerie.stringValue().to_s+@current.serie+"/Saison "+@current.saison.to_s+"/"
      when 1 then @current.repTarget = @pDirSerie.stringValue().to_s+@current.serie+"/"
      when 2 then @current.repTarget = @pDirSerie.stringValue().to_s
      end

      # Définition du fichier cible
      case @pSepRule.selectedColumn()
      when 0 then sep = "."
      when 1 then sep = " "
      when 2 then sep = "-"
      when 3 then sep = " - "
      end

      case @pFileRule.selectedRow()
      when 0 then masque = "%s%ss%02de%02d"
      when 1 then masque = "%s%s%dx%02d"
      when 2 then masque = "%s%sS%02dE%02d"
      when 3 then masque = "%s%s%d%02d"
      when 4 then masque = "%s%sSaison %d Episode %02d"
      end

      @current.fileTarget = sprintf(masque, @current.serie, sep, @current.saison, @current.episode)

    rescue Exception=>e
      puts "# SubsMgr Error # buildTargets ["+@current.fichier+"] : "+e
      @current.comment = "Pb dans l'analyse du fichier"

    end
  end
  def SerieBanner(serie)
    for i in (0..@lignesseries.size-1)
      if @lignesseries[i].nom == serie.downcase
        return @lignesseries[i].image
      end
    end
    return @lignesseries[0].image
  end
  def SerieId(serie)
    for i in (0..@lignesseries.size-1)
      if @lignesseries[i].nom == serie.downcase then return @lignesseries[i].idtvdb end
    end
    return 0
  end
  def AnalyseFichier(chaine)
    begin
      # On catche
      if chaine.match(/(.*).[Ss][0-9][0-9][Ee][0-9][0-9].*/)              # Format S01E02 ou s01e02
        temp = chaine.scan(/(.*).[Ss]([0-9]*[0-9])[Ee]([0-9][0-9]).(.*)-(.*).(avi|mkv|mp4|m4v)/)
      elsif chaine.match(/(.*).[0-9][0-9][0-9].*/)                # Format 102
        temp = chaine.scan(/(.*).([0-9]*[0-9])([0-9][0-9]).(.*)-(.*).(avi|mkv|mp4|m4v)/)
      elsif chaine.match(/(.*).[0-9]x[0-9][0-9].*/)                # Format 1x02
        temp = chaine.scan(/(.*).([0-9]*[0-9])x([0-9][0-9]).(.*)-(.*).(avi|mkv|mp4|m4v)/)
      else
        @current.serie = "Error"
        @current.saison = 0
        @current.episode = 0
        @current.infos = "Error"
        @current.team = "Error"
        @current.comment = "Format non reconnu"
        return
      end

      # On range
      @current.serie = temp[0][0].gsub(/\./, ' ').to_s.strip
      @current.saison = temp[0][1].to_i
      @current.episode = temp[0][2].to_i
      @current.infos = temp[0][3].to_s.strip
      @current.team = temp[0][4].to_s.strip

      # On traite les cas particuliers
      if @current.team.slice(/\[/) == nil
        @current.provider = ""
      else
        temp = @current.team.scan(/(.*)\.\[(.*)\]/)
        @current.team = temp[0][0].to_s
        @current.provider = temp[0][1].to_s
      end

    rescue Exception=>e
      puts "# SubsMgr Error # AnalyseFichier ["+@current.fichier+"] : "+e
      @current.serie = "Error"
      @current.saison = 0
      @current.episode = 0
      @current.infos = "Error"
      @current.team = "Error"
      @current.comment = "Pb dans l'analyse du fichier"

    end
  end


  # Méthodes des boutons de gestion des versions de sous-titres
  def ChangeInstance (sender)
    if @plusmoins.intValue == @subsTot.intValue + 1
      @plusmoins.setIntValue(@subsTot.intValue)
    elsif @plusmoins.intValue == 0
      @plusmoins.setIntValue(1)
    else
      # Changer le sous titre affiché
      @subsNb.setIntValue(@plusmoins.intValue)
      @subs.setStringValue(@current.candidats[@plusmoins.intValue-1].fichier)
      @release.setStringValue(@current.candidats[@plusmoins.intValue-1].date)
      @confiance.setIntValue(@current.candidats[@plusmoins.intValue-1].confiant)
      @source.setStringValue(@current.candidats[@plusmoins.intValue-1].source)

      # Mise à jour des petits drapeaux ...
      CalculeConfiance(@current.candidats[@plusmoins.intValue-1].fichier.downcase)
    end
  end
  ib_action :ChangeInstance

  def CalculeConfiance(sousTitre)
    begin
      # Effacer tous les drapeaux
      @errSerie.setHidden(true)
      @errSaison.setHidden(true)
      @errEpisode.setHidden(true)
      @errTeam.setHidden(true)
      @errInfos.setHidden(true)

      maConfiance = 3

      # Check du nom de la série
      if sousTitre.match(@current.serie.downcase.gsub(/ /, '.')) == nil
        maConfiance = maConfiance - 2
        @errSerie.setHidden(false)
      end

      # Check du nom de la team
      if sousTitre.match(@current.team.downcase) == nil
        maConfiance = maConfiance - 2
        @errTeam.setHidden(false)
      end

      # Check des infos supplémentaires
      if sousTitre.match(@current.infos.downcase) == nil
        maConfiance = maConfiance - 1
        @errInfos.setHidden(false)
      end

      # Check de la saison et l'épisode
      temp1 = sprintf("s%02de%02d", @current.saison, @current.episode)
      temp2 = sprintf("%d%02d", @current.saison, @current.episode)
      temp3 = sprintf("%dx%02d", @current.saison, @current.episode)
      if ((sousTitre.match(temp1)) or (sousTitre.match(temp2))  or (sousTitre.match(temp3))) == nil
        maConfiance = maConfiance - 2
        @errSaison.setHidden(false)
        @errEpisode.setHidden(false)
      end

      if (maConfiance<1) and (sousTitre != "")
        maConfiance = 1
      end

      return maConfiance

    rescue Exception=>e
      puts "# SubsMgr Error # CalculeConfiance ["+@current.fichier+"] : "+e
      @current.comment = "Pb dans l'analyse du fichier"

    end
  end





  # ------------------------------------------
  # Methodes de traitement des sous titres
  # ------------------------------------------
  def ManageAll (sender)
    totalEpisodes=numberOfRowsInTableView(@liste)
    @barre.setMinValue(0)
    @barre.setMaxValue(totalEpisodes)
    @barre.setIntValue(0)
    @barre.setHidden(false)
    @barre.displayIfNeeded
    text = ""

    for i in (0..totalEpisodes-1)
      @liste.selectRowIndexes_byExtendingSelection_(OSX::NSIndexSet.indexSetWithIndex(i), false)
      rowSelected
      if @current.status != "Traité"
        if @current.conf >= (@pConfiance.selectedColumn()+1)
          AcceptSub(@team)
          text = text+@current.fileTarget+"\n"
        end
      end
      @barre.setIntValue(i)
      @barre.displayIfNeeded

    end

    RaffraichirListe()

    # Raffraichissement des statistiques
    StatsRefresh(self)

    # Message de synthèse des épisodes traités
    alert = OSX::NSAlert.alloc().init()
    alert.setMessageText_("Episodes traités :")
    alert.setInformativeText_(text)
    alert.setAlertStyle_(OSX::NSInformationalAlertStyle)
    alert.runModal();
    @barre.setHidden(true)
  end
  ib_action :ManageAll

  def AcceptSub(sender)

    if (@current.repTarget == "") or (@current.fileTarget == "") then return end

    # Mettre à jour la liste
    @current.status = "Traité"
    @current.seriessub = ""
    @current.tvsubtitles = ""
    @current.mysource = ""
    @current.soustitreseu = ""
    @current.tvsubs = ""
    @current.local = ""
    @current.forom = ""
    @current.podnapisi = ""

    start = Time.now
    if @current.candidats[@plusmoins.intValue-1].lien != ""
      # Récupération du sous titre
      GetSub()

      # Rangement des fichiers
      CheckArbo()
      ManageFiles()

      # Mise à jour du fichier de suivi
      updateHistory(sender)
    end

    src = @current.candidats[@plusmoins.intValue-1].source
    if (kls = Plugin.constantize(src))
      Statistics.update_stats_accept(kls::INDEX, start, sender)
      @current.send("#{src.downcase}=", "©")
    else
      $stderr.puts "Je suis perdu, j'ai jamais entendu parlé de #{src}!"
    end


    # Raffraichissement de la liste
    if sender != @team
      @current.comment = "Traité en Manuel"
      if @bAttente.state == 1
        @lignes.delete(@current)
        if (numberOfRowsInTableView(@liste) > 0)
          @liste.selectRowIndexes_byExtendingSelection_(OSX::NSIndexSet.indexSetWithIndex(0), false)
          rowSelected()
        end
      end

      @liste.reloadData()

      # Raffraichissement des statistiques
      StatsRefresh(self)
    else
      @current.comment = "Traité en Automatique"
    end
  end
  ib_action :AcceptSub

  def ManageFiles()
    if File.exist?("/tmp/Sub.srt")

      # Déplacement du film
      ext = @current.fichier.split('.').last
      if (@pMove.selectedColumn() == 0)
        FileUtils.cp(@pDirTorrent.stringValue().to_s+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
      else
        FileUtils.mv(@pDirTorrent.stringValue().to_s+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
      end

      # Déplacement du sous titre
      FileUtils.mv("/tmp/Sub.srt", @current.repTarget+@current.fileTarget+".srt")

    else
      puts "Problem pour :" + @current.candidats[@plusmoins.intValue-1].source + " - " + @current.fileTarget
    end
  end
  def CheckArbo()
    # Créer l'arborescence si nécessaire
    if File.exist?(@current.repTarget) == false
      FileUtils.makedirs(@current.repTarget)
    end
  end





  # ------------------------------------------
  # Fonctions de recherche des SousTitres
  # ------------------------------------------
  def SearchAll(sender)
    totalEpisodes=numberOfRowsInTableView(@liste)
    @barre.setMinValue(0)
    @barre.setMaxValue(totalEpisodes)
    @barre.setIntValue(0)
    @barre.setHidden(false)
    @barre.displayIfNeeded

    for i in (1..totalEpisodes-1)
      @liste.selectRowIndexes_byExtendingSelection_(OSX::NSIndexSet.indexSetWithIndex(i), false)
      rowSelected()
      if @current.status != "Traité"
        SearchSub(sender)
      end

      # Raffraichissement de la fenêtre
      @liste.displayIfNeeded()
      @barre.setIntValue(i)
      @barre.displayIfNeeded
    end

    @liste.selectRowIndexes_byExtendingSelection_(OSX::NSIndexSet.indexSetWithIndex(0), false)
    rowSelected()
    if @current.status != "Traité"
      SearchSub(sender)
    end

    # Raffraichissement des statistiques
    StatsRefresh(self)

    @barre.setHidden(true)

  end
  ib_action :SearchAll

  def SearchSub(sender)
    return if @current.serie == "Error"

    @roue.startAnimation(self)

    @current.forom = "-"
    @current.seriessub = "-"
    @current.podnapisi = "-"
    @current.tvsubs = "-"
    @current.tvsubtitles = "-"
    @current.soustitreseu = "-"
    @current.mysource = "-"
    @current.local = "-"
    @current.comment = ""
    @current.candidats.clear()

    # Recherche pour les sources actives en // (enfin si ruby supporte les threads !)
    threads = []
    Plugin::LIST.each do |p|
      plugin = Plugin.constantize(p)
      if plugin && @lignessources[plugin::INDEX].active == 1
        threads << Thread.new(plugin) { |plugin|
          plugin.new(@current, @lignessources[plugin::INDEX].rank, @plusmoins.intValue-1).search_sub
        }
      end
    end
    # et on attend que tout le monde ait terminé
    threads.each {|t| t.join }

    @subsTot.setIntValue_(@current.candidats.size())
    @subsNb.setIntValue_(@current.candidats.size())
    @plusmoins.setIntValue(@current.candidats.size())
    @current.conf = 0

    # Recherche du meilleur candidat
    bestConf = 0.0
    if @current.candidats.size() != 0
      for i in (0..@current.candidats.size()-1)
        if @current.candidats[i].confiant > bestConf
          bestcandidat = i
          bestConf = @current.candidats[i].confiant
        end
      end
      @plusmoins.setIntValue(bestcandidat.to_i+1)
      @current.conf = bestConf.to_i
      ChangeInstance(self)
    end

    @liste.reloadData

    @roue.stopAnimation(self)
  end
  ib_action :SearchSub

  def ManualSearch(sender)
    # Récupération des valeurs saisies dans l'IHM
    @current.serie = @serie.stringValue().to_s
    @current.saison = @saison.intValue().to_i
    @current.episode = @episode.intValue().to_i
    @current.infos = @infos.stringValue().to_s
    @current.team = @team.stringValue().to_s

    # et on lance la recherche
    SearchSub(sender)
  end
  ib_action :ManualSearch




  # ------------------------------------------
  # Fonctions de gestion de l'historique
  # ------------------------------------------
  def HistoRollback (sender)
    begin
      # Déplacer les fichiers
      ext = @current.fichier.split('.').last
      FileUtils.mv(@current.repTarget+@current.fileTarget+".#{ext}", @pDirTorrent.stringValue().to_s+@current.fichier)
      FileUtils.rm(@current.repTarget+@current.fileTarget+".srt")

    rescue Exception=>e
      puts "# SubsMgr Error # HistoRollback ["+@current.fichier+"] : "+e
    end

    # Mettre à jour l'historique
    HistoClean(sender)

    # Mettre à jour la liste
    @current.status = "Attente"
    @current.comment = ""
    @current.seriessub = ""
    @current.tvsubtitles = ""
    @current.tvsubs = ""
    @current.local = ""
    @current.podnapisi = ""
    @current.soustitreseu = ""
    @current.mysource = ""
    @current.conf = 0

    rowSelected()
    RaffraichirListe()
  end
  ib_action :HistoRollback

  def HistoClean (sender)

    begin
      outfile = File.open('/tmp/csvout', 'wb')
      CSV::Reader.parse(File.open("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv"),';') do |row|
        if row[3] != @current.fichier
          CSV::Writer.generate(outfile, ';') do |csv|
            csv << row
          end
        end
      end
      outfile.close
      FileUtils.mv('/tmp/csvout', "/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv")

    rescue Exception=>e
      puts "# SubsMgr Error # HistoClean ["+@current.fichier+"] : "+e
    end

    if sender.description() == @bClean.description()
      @lignes.delete(@current)
      @allEpisodes.delete(@current)
      @liste.reloadData()
    end
  end
  ib_action :HistoClean

  def updateHistory(sender)
    # Identification du cas
    if sender == @team
      typeGestion = "Automatique"
    elsif sender == @bLoadSub
      toFichier = @current.serie+";"+@current.saison.to_s+";"+@current.episode.to_s+";"+@current.fichier+";None;None;Manuel;None\n"
      fichierCSV = File.open("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv",'a+')
      fichierCSV << toFichier
      fichierCSV.close
      return
    else
      typeGestion = "Manuel"
    end

    # Mise à jour du fichier de suivi
    toFichier = @current.serie+";"+@current.saison.to_s+";"+@current.episode.to_s+";"+@current.fichier+";"+@current.candidats[@plusmoins.intValue-1].fichier+";"+@current.candidats[@plusmoins.intValue-1].date+";"+typeGestion+";"+@current.candidats[@plusmoins.intValue-1].source+"\n"
    fichierCSV = File.open("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv",'a+')
    fichierCSV << toFichier
    fichierCSV.close
  end





  # ------------------------------------------
  # Fonctions de Statistiques
  # ------------------------------------------
  def Statistiques(sender)
    @fenStats.makeKeyAndOrderFront_(sender)
  end
  ib_action :Statistiques

  def StatsLoad
    @lignesstats = Statistics.load
    @listestats.reloadData
  end
  
  def StatsRAZ(sender)
    FileUtils.cp(File.join(@appPath, "SubsMgrStats.plist"), "/Library/Application\ Support/SubsMgr/SubsMgrStats.plist")
    StatsLoad()
    # Raffraichissement des statistiques
    StatsRefresh(self)
  end
  ib_action :StatsRAZ

  def StatsRefresh(sender)
    @lignesstats = Statistics.refresh
    Statistics.save
    @listestats.reloadData
  end
  ib_action :StatsRefresh


  # ------------------------------------------
  # Fonctions liées aux sous-titres
  # ------------------------------------------
  def Tester(sender)
    @fenMovie.makeKeyAndOrderFront_(sender)

    if @current.candidats[@plusmoins.intValue-1].lien != ""
      # Récupération du sous titre
      GetSub()

      if File.exist?("/tmp/Sub.srt")
        FileUtils.mv("/tmp/Sub.srt", @pDirTorrent.stringValue().to_s+@current.fichier+".srt")
        @cinema.setMovie_(OSX::QTMovie.movieWithFile(@pDirTorrent.stringValue().to_s+@current.fichier))
        @cinema.play(self)
      else
        @fenMovie.close()
      end
    end
  end
  ib_action :Tester

  def TestOK(sender)

    @cinema.pause(self)

    if File.exist?(@pDirTorrent.stringValue().to_s+@current.fichier+".srt")
      # Créer l'arbo si nécessaire
      CheckArbo()

      # Déplacement du film
      ext = @current.fichier.split('.').last
      if (@pMove.selectedColumn() == 0)
        FileUtils.cp(@pDirTorrent.stringValue().to_s+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
      else
        FileUtils.mv(@pDirTorrent.stringValue().to_s+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
      end

      # Déplacement du sous titre
      FileUtils.mv(@pDirTorrent.stringValue().to_s+@current.fichier+".srt", @current.repTarget+@current.fileTarget+".srt")

      # Mise à jour du fichier de suivi
      updateHistory(sender)

      # Raffraichissement de la liste
      if (@bAttente.state == 1)
        @lignes.delete(@current)
        if (numberOfRowsInTableView(@liste) > 0)
          @liste.selectRowIndexes_byExtendingSelection_(OSX::NSIndexSet.indexSetWithIndex(0), false)
          rowSelected()
        end
      end

      @liste.reloadData()

      @fenMovie.close()
    end
  end
  ib_action :TestOK

  def TestKO(sender)
    @cinema.pause(self)
    if File.exist?(@pDirTorrent.stringValue().to_s+@current.fichier+".srt")
      FileUtils.rm(@pDirTorrent.stringValue().to_s+@current.fichier+".srt")
    end
    @fenMovie.close()
  end
  ib_action :TestKO

  def GoWeb(sender)

    monURL = @current.candidats[@plusmoins.intValue-1].referer.to_s.strip
    return if monURL == ''
    system("open -a Safari '#{monURL}'")
  end
  ib_action :GoWeb

  def ViewSub(sender)
    if @current.candidats[@plusmoins.intValue-1].lien != ""
      # Récupération du sous titre
      GetSub()

      # Affichage du sous titre dans textedit
      if File.exist?("/tmp/Sub.srt")
        system("open -a textedit /tmp/Sub.srt")
      else
        puts "Problem dans ViewSub"
      end
    end
  end
  ib_action :ViewSub

  def LoadSub(sender)
    if @current.candidats[@plusmoins.intValue-1].lien != ""
      # Récupération du sous titre
      GetSub()

      # Déplacement du fichier dans le répertoire de sous titres
      if File.exist?("/tmp/Sub.srt")
        FileUtils.mv("/tmp/Sub.srt", @pDirSubs.stringValue().to_s+@current.candidats[@plusmoins.intValue-1].fichier+".srt")
      else
        puts "Problem dans LoadSub"
      end
    end
  end
  ib_action :LoadSub

  def NoSub(sender)

    if (@current.repTarget == "") or (@current.fileTarget == "") then return end

    # Mettre à jour la liste
    @current.status = "Traité"
    @current.seriessub = ""
    @current.tvsubtitles = ""
    @current.tvsubs = ""
    @current.local = ""
    @current.forom = ""
    @current.podnapisi = ""
    @current.mysource = ""
    @current.soustitreseu = ""

    # Rangement des fichiers
    CheckArbo()

    # Déplacement du film
    ext = @current.fichier.split('.').last
    if (@pMove.selectedColumn() == 0)
      FileUtils.cp(@pDirTorrent.stringValue().to_s+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
    else
      FileUtils.mv(@pDirTorrent.stringValue().to_s+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
    end

    # Mise à jour du fichier de suivi
    updateHistory(@bLoadSub)

    # Raffraichissement de la liste
    @current.comment = "Traité en Manuel"
    if @bAttente.state == 1
      @lignes.delete(@current)
      if (numberOfRowsInTableView(@liste) > 0)
        @liste.selectRowIndexes_byExtendingSelection_(OSX::NSIndexSet.indexSetWithIndex(0), false)
        rowSelected()
      end
    end

    @liste.reloadData()

  end
  ib_action :NoSub

  def GetSub()
    # Récupération du sous titre
    if @current.candidats[@plusmoins.intValue-1].lien != ""
      begin
        plugin = Plugin.constantize(@current.candidats[@plusmoins.intValue-1].source)
        plugin.new(@current, @lignessources[plugin::INDEX].rank, @plusmoins.intValue-1).get_from_source
      rescue NoMethodError => err
        $stderr.puts "# SubsMgr Error # GetSub [ #{@current.fichier} ] - #{err.inspect}"
      end
    end

    # Post Traitements
    if @bSupprCrochets.state() == 1 then system('sed -e "s/\<[^\>]*\>//g" /tmp/Sub.srt > /tmp/Sub2.srt'); FileUtils.mv("/tmp/Sub2.srt", "/tmp/Sub.srt") end
    if @bSupprAccolades.state() == 1 then system('sed -e "s/{[^}]*}//g" /tmp/Sub.srt > /tmp/Sub2.srt'); FileUtils.mv("/tmp/Sub2.srt", "/tmp/Sub.srt") end
    if @bCommande.state() == 1 then system(@pCommande.stringValue().to_s) end
  end


  # ------------------------------------------
  # Fonctions liées aux répertoires et TVdb
  # ------------------------------------------
  def ViewDir(sender)
    if File.exist?(@current.repTarget)
      system("open -a Finder '"+@current.repTarget+"'")
    end
  end
  ib_action :ViewDir

  def SerieInfos(sender)

    @roue.startAnimation(self)

    ovserie = @current.serie
    @ovimage.setImage(SerieBanner(ovserie))

    tableau = []
    index = 0

    if ovserie != ""
      # Recherche de la page de la saison
      monURL = "http://www.thetvdb.com/?tab=series&id="+SerieId(ovserie)
      doc = FileCache.get_html(monURL)
      doc.search("//a.seasonlink").each do |k|
        if k.text.to_s == @current.saison.to_s
          monURL = "http://www.thetvdb.com"+k[:href].to_s
        end
      end

      # Lecture des épisodes
      doc = FileCache.get_html(monURL)
      doc.search("table#listtable tr").each do |k|
        k.search("td[@class='odd'|'even']").each do |k2|
          tableau[index]=k2.text.to_s
          index = index + 1
        end
      end
    end


    # Remplissage du tableau et vérification du status
    @lignesinfos.clear()
    subsok = 0
    chargeok = 0
    for i in (1..((index-1)/4))
      new_ligne = InfosSaison.new
      new_ligne.episode = tableau[i*4]
      new_ligne.titre = tableau[(i*4)+1]
      new_ligne.diffusion = tableau[(i*4)+2]
      new_ligne.telecharge = 0
      new_ligne.soustitre = 0

      temp1 = sprintf("s%02de%02d", @current.saison, new_ligne.episode.to_i)
      temp2 = sprintf("%d%02d", @current.saison, new_ligne.episode.to_i)
      temp3 = sprintf("%dx%02d", @current.saison, new_ligne.episode.to_i)

      # Recherche de l'épisode
      for j in (0..@allEpisodes.size()-1)
        if @allEpisodes[j].fichier.downcase.match(ovserie.downcase) or @allEpisodes[j].fichier.downcase.match(ovserie.downcase.gsub(/ /, '.'))
          if @allEpisodes[j].fichier.downcase.match(temp1) or @allEpisodes[j].fichier.downcase.match(temp2) or @allEpisodes[j].fichier.downcase.match(temp3)
            new_ligne.telecharge = 1
            chargeok = chargeok + 1
            if @allEpisodes[j].status == "Traité"
              new_ligne.soustitre = 1
              subsok = subsok + 1
            end
          end
        end
      end

      @lignesinfos << new_ligne
    end

    # Calcul des stats
    temp = sprintf("Downloaded : %.1f %", chargeok*100/@lignesinfos.size())
    @ovcharge.setStringValue_(temp)
    temp = sprintf("Subtitled : %.1f %", subsok*100/@lignesinfos.size())
    @ovsubs.setStringValue_(temp)

    @ovliste.reloadData

    @roue.stopAnimation(self)

    @fenInfos.makeKeyAndOrderFront_(sender)

  end
  ib_action :SerieInfos

  def SwitchView()
    taille = OSX::NSSize.new()

    if @vue.subviews[0].frame.width == 227.0
      while @vue.subviews[0].frame.width < 830.0
        taille.width = 832.0
        @vue.subviews[0].setFrameSize_(taille)
        @vue.displayIfNeeded
      end
      @bCleanSerie.setHidden(false)
      @bWebSerie.setHidden(false)
    else
      while @vue.subviews[0].frame.width > 227.0
        taille.width = 227.0
        @vue.subviews[0].setFrameSize_(taille)
        @vue.displayIfNeeded
      end
      @bCleanSerie.setHidden(true)
      @bWebSerie.setHidden(true)
    end

  end
  ib_action :SwitchView

  def GoWebSerie(sender)
    system("open -a Safari '"+@URLTVdb+"'")
  end
  ib_action :GoWebSerie

  def CleanSerie(sender)


  end
  ib_action :CleanSerie


  # ------------------------------------------
  # Fonctions de gestion des préférences
  # ------------------------------------------
  def Preferences (sender)
    @fenPref.makeKeyAndOrderFront_(sender)
  end
  ib_action :Preferences

  def PrefValid(sender)
    # Onglet Directories
    @prefs["Directories"]["Download"] = @pDirTorrent.stringValue()
    @prefs["Directories"]["Series"] = @pDirSerie.stringValue()
    @prefs["Directories"]["Banners"] = @pDirBanner.stringValue()
    @prefs["Directories"]["Subtitles"] = @pDirSubs.stringValue()
    @prefs["Directories"]["Torrents"] = @pDirTorrents.stringValue()

    # Onglet Naming Rules
    @prefs["Naming Rules"]["Directories"] = @pDirRule.selectedRow()
    @prefs["Naming Rules"]["Episodes"] = @pFileRule.selectedRow()
    @prefs["Naming Rules"]["Separator"] = @pSepRule.selectedColumn()

    # Onglet Automatism
    @prefs["Automatism"]["Min confidence"] = @pConfiance.selectedColumn()
    @prefs["Automatism"]["Schedule SearchAll"] = @pSchedSearch.indexOfSelectedItem()
    @prefs["Automatism"]["Schedule ProcessAll"] = @pSchedProcess.indexOfSelectedItem()
    @prefs["Automatism"]["Forom key"] = @pForomKey.stringValue()

    # Onglet Sources
    j = 0
    for i in ["Forom", "Podnapisi", "SeriesSub", "SousTitresEU", "TVSubs", "TVSubtitles", "Local", "MySource"]
      @prefs["Sources"][i]["Active"] = @lignessources[j].active
      @prefs["Sources"][i]["Ranking"] = @lignessources[j].rank
      j = j+1
    end

    # Onglet Subs management
    @prefs["Subs management"]["Move"] = @pMove.selectedColumn()
    @prefs["Subs management"]["SupprCrochets"] = @pSupprCrochets.state()
    @prefs["Subs management"]["SupprAccolades"] = @pSupprAccolades.state()
    @prefs["Subs management"]["Commande"] = @pCommande.stringValue()


    @prefs.save_plist("/Library/Application Support/SubsMgr/SubsMgrPrefs.plist")
    PrefRefreshMain()
    @fenPref.close()
  end
  ib_action :PrefValid

  def PrefCancel(sender)
    # Lecture du plist
    @prefDefault = Plist::parse_xml(File.join(@appPath, "SubsMgrPrefs.plist"))
    @prefCurrent = Plist::parse_xml("/Library/Application Support/SubsMgr/SubsMgrPrefs.plist")
    @prefs = @prefDefault.deep_merge(@prefCurrent)

    # Onglet Directories
    @pDirTorrent.setStringValue(@prefs["Directories"]["Download"])
    @pDirSerie.setStringValue(@prefs["Directories"]["Series"])
    @pDirBanner.setStringValue(@prefs["Directories"]["Banners"])
    @pDirSubs.setStringValue(@prefs["Directories"]["Subtitles"])
    @pDirTorrents.setStringValue(@prefs["Directories"]["Torrents"])

    # Onglet Naming Rules
    @pDirRule.selectCellAtRow_column_(@prefs["Naming Rules"]["Directories"], 0)
    @pFileRule.selectCellAtRow_column_(@prefs["Naming Rules"]["Episodes"], 0)
    @pSepRule.selectCellAtRow_column_(0, @prefs["Naming Rules"]["Separator"])

    # Onglet Automatism
    @pConfiance.selectCellAtRow_column_(0, @prefs["Automatism"]["Min confidence"])
    @pSchedSearch.selectItemAtIndex(@prefs["Automatism"]["Schedule SearchAll"])
    @pSchedProcess.selectItemAtIndex(@prefs["Automatism"]["Schedule ProcessAll"])
    @pForomKey.setStringValue(@prefs["Automatism"]["Forom key"])

    # Onglet Sources
    j = 0
    for i in ["Forom", "Podnapisi", "SeriesSub", "SousTitresEU", "TVSubs", "TVSubtitles", "Local", "MySource"]
      @lignessources[j].active = @prefs["Sources"][i]["Active"]
      @lignessources[j].rank = @prefs["Sources"][i]["Ranking"]
      j = j+1
    end

    # Onglet Subs management
    @pMove.selectCellAtRow_column_(0, @prefs["Subs management"]["Move"])
    @pSupprCrochets.setState(@prefs["Subs management"]["SupprCrochets"])
    @pSupprAccolades.setState(@prefs["Subs management"]["SupprAccolades"])
    @pCommande.setStringValue(@prefs["Subs management"]["Commande"])

    PrefRefreshMain()
    @fenPref.close()

  end
  ib_action :PrefCancel

  def PrefRefreshMain()
    # maj plugins specifiques
    Plugin::Forom.forom_key = @pForomKey.stringValue().to_s
    Plugin::Local.local_path = @pDirSubs.stringValue().to_s

    # Affichage des sources actives dans la liste des épisodes
    @sourcesActives = 0

    @source3.setImage(Icones.list["None"])
    @liste.tableColumns[5].setIdentifier("None")
    @liste.tableColumns[5].setHeaderToolTip("None")
    @source2.setImage(Icones.list["None"])
    @liste.tableColumns[4].setIdentifier("None")
    @liste.tableColumns[4].setHeaderToolTip("None")
    @source1.setImage(Icones.list["None"])
    @liste.tableColumns[3].setIdentifier("None")
    @liste.tableColumns[3].setHeaderToolTip("None")

    for i in 0..7
      if @lignessources[i].active == 1
        if @sourcesActives == 2
          @source3.setImage(@lignessources[i].image)
          @sourcesActives = 3
          @liste.tableColumns[5].setIdentifier(@lignessources[i].source)
          @liste.tableColumns[5].setHeaderToolTip(@lignessources[i].source)
        end
        if @sourcesActives == 1
          @source2.setImage(@lignessources[i].image)
          @sourcesActives = 2
          @liste.tableColumns[4].setIdentifier(@lignessources[i].source)
          @liste.tableColumns[4].setHeaderToolTip(@lignessources[i].source)
        end
        if @sourcesActives == 0
          @source1.setImage(@lignessources[i].image)
          @sourcesActives = 1
          @liste.tableColumns[3].setIdentifier(@lignessources[i].source)
          @liste.tableColumns[3].setHeaderToolTip(@lignessources[i].source)
        end
      end
    end
    @liste.reloadData()

    # Affichage des flags de Suppression des tags
    @bSupprCrochets.setState(@pSupprCrochets.state())
    @bSupprAccolades.setState(@pSupprAccolades.state())
    if @pCommande.stringValue() == "" then @bCommande.setState(0) else @bCommande.setState(1) end
  end

  def PrefSourceModif(sender)
    @alertMessage.setStringValue("")
    @rankSource.setIntValue(@lignessources[@listesources.selectedRow()].rank)
    @activeSource.setState(@lignessources[@listesources.selectedRow()].active)
    @nomSource.setStringValue(@lignessources[@listesources.selectedRow()].source)
    @fenSource.makeKeyAndOrderFront_(sender)
  end
  ib_action :PrefSourceModif

  def PrefSourceValid(sender)
    if (@activeSource.state() == 1) and (@sourcesActives == 3) then @alertMessage.setStringValue("You already activated 3 sources"); return; end
    if (@activeSource.state() == 0) and (@lignessources[@listesources.selectedRow()].active == 1) then @sourcesActives = @sourcesActives - 1; end

    @lignessources[@listesources.selectedRow()].active = @activeSource.state()
    @lignessources[@listesources.selectedRow()].rank = @rankSource.intValue()
    @listesources.reloadData()
    @fenSource.close()
  end
  ib_action :PrefSourceValid

  def PrefSourceCancel(sender)
    @fenSource.close()
  end
  ib_action :PrefSourceCancel

  def PrefDirChoose(sender)
    panel = OSX::NSOpenPanel.alloc().init()
    panel.setCanChooseFiles_(false)
    panel.setCanChooseDirectories_(true)
    panel.setAllowsMultipleSelection_(false)

    if panel.runModal() == 1
      if (sender.description() == @pDirSubsButton.description())
        @pDirSubs.setStringValue(panel.filename()+"/")
      end
      if (sender.description() == @pDirSerieButton.description())
        @pDirSerie.setStringValue(panel.filename()+"/")
      end
      if (sender.description() == @pDirTorrentButton.description())
        @pDirTorrent.setStringValue(panel.filename()+"/")
      end
      if (sender.description() == @pDirBannerButton.description())
        @pDirBanner.setStringValue(panel.filename()+"/")
      end
      if (sender.description() == @pDirTorrentsButton.description())
        @pDirTorrents.setStringValue(panel.filename()+"/")
      end
    end
  end
  ib_action :PrefDirChoose

end
