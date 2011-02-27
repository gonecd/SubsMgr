#
#	 SubsMgr.rb
#	 SubsMgr
#
#	 Created by Cyril DELAMARE on 31/01/09.
#	 Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

$LOAD_PATH << File.join(File.dirname(__FILE__), "common")
$LOAD_PATH << File.join(File.dirname(__FILE__), "plugin")

ENV['RUBYCOCOA_THREAD_HOOK_DISABLE'] = '1' # disable thread warning

require 'osx/cocoa'
require 'common'

Tools.logger.level = 0 

class SubsMgr < OSX::NSWindowController
	# ------------------------------------------
	# Pointeurs sur les objets de l'IHM
	# ------------------------------------------

	ib_outlets :serie, :saison, :episode, :team, :infos, :liste, :listeseries, :image, :fileTarg, :repTarg
	ib_outlets :subs, :release, :subsNb, :subsTot, :roue, :barre, :confiance, :plusmoins, :source
	ib_outlets :bFiltre, :listestats, :bSupprCrochets, :bSupprAccolades, :bCommande
	ib_outlets :source1, :source2, :source3
	ib_outlets :refreshItem
	
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
	ib_outlets :bSearch, :bAccept, :bClean, :bRollback, :bManual, :bNoSub
	ib_outlets :bTest, :bGoWeb, :bLoadSub, :bViewSub, :bDir
	ib_outlets :bCleanSerie, :bWebSerie, :bInfoSerie

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
		@lignesinfos = []
		@lignessources = []
		@ligneslibrary = []
		@seriesBanners = {}
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
		unless File.exist?("/Library/Application\ Support/SubsMgr/SubsMgrSeries.plist")
			FileUtils.cp(File.join(@appPath, "SubsMgrSeries.plist"), "/Library/Application\ Support/SubsMgr/SubsMgrSeries.plist")
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
		Plugin::Forom.forom_key = @prefs["Automatism"]["Forom key"]
		Plugin::Local.local_path = @prefs["Directories"]["Subtitles"]

		# Initialisation des banières de séries
		@series = Plist::parse_xml("/Library/Application\ Support/SubsMgr/SubsMgrSeries.plist")
		initBanners()

		# Initialisation des Statistiques
		StatsRAZ(self) unless File.exist?("/Library/Application\ Support/SubsMgr/SubsMgrStats.plist")
		StatsLoad()
		StatsRefresh(self)

		# Construction des listes de series et d'episodes
		Refresh(self)
		@fenWait.close()

		manageButtons("Clear")
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

			# On se posionne sur le meilleur sous titre trouvé
			if @current.candidats.size>0
				bestConf = @current.candidats.collect {|e|e.confiant.to_f}.max
				bestcandidat = 
				bestConf = @current.candidats[0].confiant
				bestcandidat = 0
				for i in (0..@current.candidats.size()-1)
					if @current.candidats[i].confiant > bestConf
						bestcandidat = i
						bestConf = @current.candidats[i].confiant
					end
				end
				@subsTot.setIntValue_(@current.candidats.size)
				@subsNb.setIntValue_(@current.candidats.size)
				@plusmoins.setIntValue(bestcandidat+1)
				ChangeInstance(self)
			end

			# Gestion de l'affichage des boutons
			if @current.status == "Traité"
				manageButtons("EpisodeTraité")
			else
				manageButtons("EpisodeAttente")
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

		manageButtons("Library")
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
			when /ep[0-9]+/im : if ligne.episodes[column.identifier.gsub(/ep/im, '').to_i-1] then ligne.episodes[column.identifier.gsub(/ep/im, '').to_i-1]["Statut"] else nil end
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

	def Refresh (sender)
		case @refreshItem.indexOfSelectedItem()
		when 0
			RelisterEpisodes()
			RelisterSeries()
			RelisterInfos()
			AnalyseInfosSaison()
			RaffraichirListe()
		when 2
			RelisterEpisodes()
			AnalyseInfosSaison()
			RaffraichirListe()
		when 3
			RelisterSeries()
			AnalyseInfosSaison()
		when 4
			RelisterInfos()
			AnalyseInfosSaison()
		else
			puts "Refresh : cas non implémenté"
		end
	end
	ib_action :Refresh


	def RelisterEpisodes
		# Vider la liste
		@allEpisodes.clear

		# Préparation des variables de traitement
		libCSV = {}
		case @prefs["Naming Rules"]["Separator"]
			when 0 then sep = "."
			when 1 then sep = " "
			when 2 then sep = "-"
			when 3 then sep = " - "
		end
		case @prefs["Naming Rules"]["Episodes"]
			when 0 then masque = "%s%ss%02de%02d"
			when 1 then masque = "%s%s%dx%02d"
			when 2 then masque = "%s%sS%02dE%02d"
			when 3 then masque = "%s%s%d%02d"
			when 4 then masque = "%s%sSaison %d Episode %02d.avi"
		end
		
		# Récupération des données dans le fichier CSV
		File.open("/Library/Application\ Support/SubsMgr/SubsMgrHistory.csv").each do |line|
		begin
			row = CSV.parse_line(line,';')
			raise CSV::IllegalFormatError unless (row && row.size == 8)
		
			# On parse la liste des épisodes
			ext = row[3].split('.').last
			balise = sprintf(masque+"."+ext, row[0], sep, row[1], row[2])
			libCSV[balise] = {	"FichierSource" => row[3], 
								"FichierSRT" => row[4], 
								"Date" => row[5], 
								"AutoManuel" => row[6], 
								"Source" => row[7]} 
			
			rescue CSV::IllegalFormatError => err
				$stderr.puts "# SubsMgr Error # Invalid CSV history line skipped:\n#{line}"
			end
		end
				
		# Récupération des torrents en attente de download
		if File.exist?(@prefs["Directories"]["Torrents"])
			Dir.chdir(@prefs["Directories"]["Torrents"])
			Dir.glob("*.torrent").each do |x|
				new_ligne = Ligne.new
				new_ligne.fichier = x
				new_ligne.date = File.mtime(x)
				new_ligne.conf = 0
				new_ligne.comment = ""
				new_ligne.status = "Unloaded"
				new_ligne.candidats = []
				@allEpisodes << new_ligne

				# Mise à jour des infos calculées
				@current = new_ligne
				AnalyseTorrent(@current.fichier)
			end
		end

		# Récupération des fichiers en attente de traitement
		if File.exist?(@prefs["Directories"]["Download"])
			Dir.chdir(@prefs["Directories"]["Download"])
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
		if File.exist?(@prefs["Directories"]["Series"])
			Dir.chdir(@prefs["Directories"]["Series"])
			Dir.glob("*/*/*.{avi,mkv,mp4,m4v}").each do |x|
				new_ligne = Ligne.new
				new_ligne.fichier = File.basename(x)
				new_ligne.date = File.mtime(x)
				new_ligne.conf = 0
				new_ligne.comment = ""
				new_ligne.status = "Traité"
				new_ligne.candidats = []
				@allEpisodes << new_ligne

				# Mise à jour des infos calculées
				@current = new_ligne
				AnalyseEpisode(@current.fichier)
				buildTargets()
				
				# Mise à jour des infos d'historique si elle existent
				if libCSV[new_ligne.fichier] != nil
					new_candid = WebSub.new
					new_candid.fichier = libCSV[new_ligne.fichier]["FichierSRT"]
					new_candid.date = libCSV[new_ligne.fichier]["AutoManuel"]
					new_candid.lien = libCSV[new_ligne.fichier]["Date"]
					new_candid.confiant = 0
					new_candid.source = libCSV[new_ligne.fichier]["Source"]
					new_candid.referer = "None"
					
					@current.candidats << new_candid
					@current.fichier = libCSV[new_ligne.fichier]["FichierSource"]
					AnalyseFichier(@current.fichier)
					@current.candidats[0].confiant = CalculeConfiance(@current.candidats[0].fichier.downcase)
					@current.conf = @current.candidats[0].confiant
				end
			end
		end

		@allEpisodes.sort! {|x,y| x.fichier <=> y.fichier }
	end
	def RelisterSeries
		@ligneslibrary.clear

		# On ajoute la ligne "All series"
		new_ligne = Library.new
		new_ligne.image = @seriesBanners["."]
		new_ligne.serie = "."
		new_ligne.saison = 0
		new_ligne.URLTVdb = "http://www.thetvdb.com/"
		new_ligne.nbepisodes = ""
		new_ligne.episodes = []
		@ligneslibrary << new_ligne

		# On parse tous les épisodes pour construire la liste des séries
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
				new_ligne.image = SerieBanner(episode.serie.downcase)
				new_ligne.episodes = []
		
				@ligneslibrary << new_ligne
			end		
		end

		@ligneslibrary.sort! {|x,y| x.serie+x.saison.to_s <=> y.serie+y.saison.to_s }


		# On ajoute la ligne "Errors"
		new_ligne = Library.new
		new_ligne.image = @seriesBanners["."]
		new_ligne.serie = "Error"
		new_ligne.saison = 0
		new_ligne.URLTVdb = "http://www.thetvdb.com/"
		new_ligne.nbepisodes = ""
		new_ligne.episodes = []
		@ligneslibrary << new_ligne

		@listeseries.reloadData()
	end
	def RelisterInfos()

		@ligneslibrary.each do |maserie|
			if maserie.serie == "." or maserie.serie == "Error" then next end
			
			# Recherche de la page de la saison sur TheTVdb
			monURL = "http://www.thetvdb.com/?tab=series&id="+SerieId(maserie.serie.to_s.downcase).to_s
			if monURL == "http://www.thetvdb.com/?tab=series&id=0" then next end
			doc = FileCache.get_html(monURL)
			doc.search("a.seasonlink").each do |k|
				if k.text.to_s == maserie.saison.to_s
					monURL = "http://www.thetvdb.com"+k[:href].to_s
					maserie.URLTVdb = monURL
				end
			end
			
			# Lecture des épisodes
			maserie.episodes = []
			numero = titre = diffusion = nil
			
			doc = FileCache.get_html(monURL)
			doc.search("table#listtable tr td").each_with_index do |k, index|
				next unless k['class'].match(/odd|even/im)
				case index.modulo(4)
				when 0: numero = k.text.to_i
				when 1: titre = k.text
				when 2: diffusion = k.text
				when 3: maserie.episodes << {"Episode" => numero, "Titre" => titre, "Diffusion" => diffusion, "Statut" => nil}
				end
			end
			
			maserie.nbepisodes = maserie.episodes.size()
		end
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
				if episode.serie.downcase.match(@serieSelectionnee.downcase) and episode.serie.downcase.match(@spotFilter.downcase) and episode.saison == @saisonSelectionnee
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

	def manageButtons(modeAffichage)
		# On efface tous les boutons
		@bSearch.setHidden(true)
		@bAccept.setHidden(true)
		@bManual.setHidden(true)
		@bRollback.setHidden(true)
		@bClean.setHidden(true)
		@bNoSub.setHidden(true)

		@bLoadSub.setHidden(true)
		@bGoWeb.setHidden(true)
		@bViewSub.setHidden(true)
		@bTest.setHidden(true)
		@bDir.setHidden(true)

		@bCleanSerie.setHidden(true)
		@bWebSerie.setHidden(true)
		@bInfoSerie.setHidden(true)

		case modeAffichage
		when "Episodes"						# Mode Episodes
			@bSearch.setHidden(false)
			@bAccept.setHidden(false)
			@bManual.setHidden(false)
			@bRollback.setHidden(false)
			@bClean.setHidden(false)
			@bNoSub.setHidden(false)

			if @source.stringValue() != ""
				@bLoadSub.setHidden(false)
				@bGoWeb.setHidden(false)
				@bViewSub.setHidden(false)
				@bTest.setHidden(false)
			end
			if (@fileTarg.stringValue() != "") and (@fileTarg.stringValue() != "Error s00e00")
				@bDir.setHidden(false)
			end
		when "EpisodeTraité"
			@bRollback.setHidden(false)
			@bClean.setHidden(false)

			if (@fileTarg.stringValue() != "") and (@fileTarg.stringValue() != "Error s00e00")
				@bDir.setHidden(false)
			end
		when "EpisodeAttente"
			@bSearch.setHidden(false)
			@bAccept.setHidden(false)
			@bManual.setHidden(false)
			@bNoSub.setHidden(false)

			if @source.stringValue() != ""
				@bLoadSub.setHidden(false)
				@bGoWeb.setHidden(false)
				@bViewSub.setHidden(false)
				@bTest.setHidden(false)
			end
			if (@fileTarg.stringValue() != "") and (@fileTarg.stringValue() != "Error s00e00")
				@bDir.setHidden(false)
			end
		when "Library"						# Mode Library
			@bCleanSerie.setHidden(false)
			@bWebSerie.setHidden(false)
			@bInfoSerie.setHidden(false)
		end
	end
	def clearResults()
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
		@image.setImage(@ligneslibrary[0].image)
	end
	def buildTargets()
		begin
			# Définition du répertoire cible
			case @prefs["Naming Rules"]["Directories"]
			when 0 then @current.repTarget = @prefs["Directories"]["Series"]+@current.serie+"/Saison "+@current.saison.to_s+"/"
			when 1 then @current.repTarget = @prefs["Directories"]["Series"]+@current.serie+"/"
			when 2 then @current.repTarget = @prefs["Directories"]["Series"]
			end

			# Définition du fichier cible
			case @prefs["Naming Rules"]["Separator"]
			when 0 then sep = "."
			when 1 then sep = " "
			when 2 then sep = "-"
			when 3 then sep = " - "
			end

			case @prefs["Naming Rules"]["Episodes"]
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
	
	def initBanners()
		@series.each() do |serie|
			@seriesBanners[serie[0]] = OSX::NSImage.alloc.initWithContentsOfFile_(@prefs["Directories"]["Banners"]+@series[serie[0]]["Banner"])
		end
	end
	def SerieBanner(myserie)
		# Connait-on la série ?
		connue = @series.any? do |serie|
			(serie[0] == myserie)
		end

		if !connue
			# Recherche sur TheTVdb
			monURL = "http://www.thetvdb.com/api/GetSeries.php?seriesname="+myserie.gsub(/ /, '+')
			doc = FileCache.get_html(monURL, :xml => true)
			found = 0
			linkBanner = " "
			doc.search("Series").each do |k|
				if k.search("SeriesName").inner_html.downcase.to_s == myserie.downcase.to_s
					@series[myserie] = {"Id" => k.search("seriesid").inner_html.downcase.to_s, "Banner" => myserie+".jpg"}
					linkBanner = k.search("banner").inner_html.downcase.to_s
					@series.save_plist("/Library/Application\ Support/SubsMgr/SubsMgrSeries.plist")
					found = 1
					break 
				end
			end
			
			if found == 1
				# On loade la bannière sur theTVdb
				FileUtils.cp(FileCache.get_file("http://www.thetvdb.com/banners/"+linkBanner), @prefs["Directories"]["Banners"]+@series[myserie]["Banner"])
				@seriesBanners[myserie] = OSX::NSImage.alloc.initWithContentsOfFile_(@prefs["Directories"]["Banners"]+@series[myserie]["Banner"])
				return @seriesBanners[myserie]
			else
				return @seriesBanners["."]
			end
		else
			return @seriesBanners[myserie]
		end
	end
	def SerieId(myserie)
		# Connait-on la série ?
		connue = @series.any? do |serie|
			(serie[0] == myserie)
		end

		if connue
			return @series[myserie]["Id"]
		else
			return 0
		end
	end
	
	def AnalyseFichier(chaine)
		begin
			# dans l'ordre du plus précis au moins précis (en particulier le format 101 se telescope avec les autres infos du type 720p ou x264)

			# Format s01e02 ou variantes (s1e1, s01e1, s1e01)
			temp = chaine.match(/(.*?).s([0-9]{1,2})e([0-9]{1,2})([\._\s-].*)*\.(avi|mkv|mp4|m4v)/i)
			# Format 1x02 ou 01x02
			temp = chaine.match(/(.*?).([0-9]{1,2})x([0-9]{1,2})([\._\s-].*)*\.(avi|mkv|mp4|m4v)/i) unless temp
			# Format 102
			temp = chaine.match(/(.*?).([0-9]{1,2})([0-9]{2})([\._\s-].*)*\.(avi|mkv|mp4|m4v)/i) unless temp

			unless temp
				@current.serie = "Error"
				@current.saison = 0
				@current.episode = 0
				@current.infos = "Error"
				@current.team = "Error"
				@current.comment = "Format non reconnu"
				return
			end

			# On range
			@current.serie = temp[1].gsub(/\./, ' ').to_s.strip
			@current.saison = temp[2].to_i
			@current.episode = temp[3].to_i

			# et on traite les infos correctement pour eliminer l'eventuel titre d'épisode
			infos = temp[4].split('-')

			# la team est toujours après le dernier tiret, suivi eventuellement d'un provider)
			(team, provider) = infos.pop.to_s.split(/\./, 2)
			@current.team = team.to_s
			@current.provider = provider.to_s.gsub(/[\[\]]+/im, '')

			# on peut maintenant récupérer les vrais infos
			infos = infos.join("-").to_s
			if (m = infos.match(/^.*?((REPACK|PROPER|720p|HDTV|PDTV|WSR)\.(.+))/im))
				@current.infos = m[1].gsub(/((xvid|x264|divx).+)/im, '').gsub(/(^[^a-z0-9]+|[^a-z0-9]$)/im, '').strip
			else
				@current.infos = infos.gsub(/(^[^a-z0-9]+|[^a-z0-9]$)/im, '').strip
			end
			@current.infos << ".#{@current.provider}" if (@current.provider != '')

			if chaine.match(/720p/im)
				@current.format = '720p'
				# dans les sous-titres, ils ne reprécisent pas hdtv si c'est du 720p, cela va de soit a priori
				@current.infos.gsub!(/720p.hdtv/im, '720p')
			end

		rescue Exception=>e
			puts "# SubsMgr Error # AnalyseFichier [#{@current.fichier}] : #{e}"
			@current.serie = "Error"
			@current.saison = 0
			@current.episode = 0
			@current.infos = "Error"
			@current.team = "Error"
			@current.comment = "Pb dans l'analyse du fichier"
		end
		@current
	end
	def AnalyseTorrent(chaine)
		begin
			# On catche
			if chaine.match(/(.*) — [0-9]x[0-9][0-9].torrent/)								# Format 1x02
				temp = chaine.scan(/(.*) — ([0-9]*[0-9])x([0-9][0-9]).torrent/)
			else
				@current.serie = "Error"
				@current.saison = 0
				@current.episode = 0
				@current.infos = ""
				@current.team = ""
				@current.comment = "Format non reconnu"
				return
			end

			# On range
			@current.serie = temp[0][0].gsub(/\./, ' ').to_s.strip
			@current.saison = temp[0][1].to_i
			@current.episode = temp[0][2].to_i
			@current.infos = ""
			@current.team = ""

		rescue Exception=>e
			puts "# SubsMgr Error # AnalyseTorrent [#{@current.fichier}] : #{e}\n#{e.backtrace.join("\n")}"
			@current.serie = "Error"
			@current.saison = 0
			@current.episode = 0
			@current.infos = ""
			@current.team = ""
			@current.comment = "Pb dans l'analyse du fichier"

		end
	end
	def AnalyseEpisode(chaine)
		begin
			# On catche
			if chaine.match(/(.*).[Ss][0-9][0-9][Ee][0-9][0-9].*/)							# Format S01E02 ou s01e02
				temp = chaine.scan(/(.*).[Ss]([0-9]*[0-9])[Ee]([0-9][0-9]).(avi|mkv|mp4|m4v)/)
			else
				@current.serie = "Error"
				@current.saison = 0
				@current.episode = 0
				@current.infos = ""
				@current.team = ""
				@current.comment = "Format non reconnu"
				return
			end

			# On range
			@current.serie = temp[0][0].gsub(/\./, ' ').to_s.strip
			@current.saison = temp[0][1].to_i
			@current.episode = temp[0][2].to_i
			@current.infos = ""
			@current.team = ""

		rescue Exception=>e
			puts "# SubsMgr Error # AnalyseEpisode ["+@current.fichier+"] : "+e
			@current.serie = "Error"
			@current.saison = 0
			@current.episode = 0
			@current.infos = ""
			@current.team = ""
			@current.comment = "Pb dans l'analyse du fichier"

		end
	end
	
	def AnalyseInfosSaison()

		@ligneslibrary.each do |maserie|
			if maserie.serie == "." or maserie.serie == "Error" then next end
			
			# Analyse des épisodes de la saison
			maserie.episodes.each do |myepisode|
				begin
					if Date.parse(myepisode["Diffusion"]) < Date.today()
						myepisode["Statut"] = Icones.list["Aired"]
					
						subtitled = @allEpisodes.any? do |eps|
							(eps.serie.downcase.to_s == maserie.serie) and (eps.saison == maserie.saison) and (eps.episode == myepisode["Episode"]) and (eps.status == "Traité")
						end
				
						vidloaded = @allEpisodes.any? do |eps|
							(eps.serie.downcase.to_s == maserie.serie) and (eps.saison == maserie.saison) and (eps.episode == myepisode["Episode"]) and (eps.status == "Attente")
						end

						torrentloaded = @allEpisodes.any? do |eps|
							(eps.serie.downcase.to_s == maserie.serie) and (eps.saison == maserie.saison) and (eps.episode == myepisode["Episode"]) and (eps.status == "Unloaded")
						end

						if subtitled then myepisode["Statut"] = Icones.list["Subtitled"] end
						if vidloaded then myepisode["Statut"] = Icones.list["VideoLoaded"] end
						if torrentloaded then myepisode["Statut"] = Icones.list["TorrentLoaded"] end
					else
						myepisode["Statut"] = Icones.list["NotAired"]
						maserie.status = Icones.list["NotAired"]
					end
				
				rescue Exception=>e
					myepisode["Statut"] = Icones.list["NotAired"]
					maserie.status = Icones.list["NotAired"]
				end
			end
			
			# Calcul du statut global de la saison
			maserie.status = Icones.list["Subtitled"]
			
			vidloaded = maserie.episodes.any? do |eps| (eps["Statut"] == Icones.list["VideoLoaded"]) end
			if vidloaded then maserie.status = Icones.list["VideoLoaded"] end
			
			torrentloaded = maserie.episodes.any? do |eps| (eps["Statut"] == Icones.list["TorrentLoaded"]) end
			if torrentloaded then maserie.status = Icones.list["TorrentLoaded"] end
			
			aired = maserie.episodes.any? do |eps| (eps["Statut"] == Icones.list["Aired"]) end
			if aired then maserie.status = Icones.list["Aired"] end
			
			notaired = maserie.episodes.any? do |eps| (eps["Statut"] == Icones.list["NotAired"]) end
			if notaired then maserie.status = Icones.list["NotAired"] end
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
			if ((sousTitre.match(temp1)) or (sousTitre.match(temp2))	or (sousTitre.match(temp3))) == nil
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
				if @current.conf >= (@prefs["Automatism"]["Min confidence"]+1)
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
			if (@prefs["Subs management"]["Move"] == 0)
				FileUtils.cp(@prefs["Directories"]["Download"]+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
			else
				FileUtils.mv(@prefs["Directories"]["Download"]+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
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
		@current.candidats.sort!
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

		# Construire les fichiers et répertoire Targets
		buildTargets()
		@repTarg.setStringValue(@current.repTarget)
		@fileTarg.setStringValue(@current.fileTarget)

		# et on lance la recherche
		SearchSub(sender)

		manageButtons("EpisodeAttente")
	end
	ib_action :ManualSearch




	# ------------------------------------------
	# Fonctions de gestion de l'historique
	# ------------------------------------------
	def HistoRollback (sender)
		begin
			# Déplacer les fichiers
			ext = @current.fichier.split('.').last
			FileUtils.mv(@current.repTarget+@current.fileTarget+".#{ext}", @prefs["Directories"]["Download"]+@current.fichier)
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
				FileUtils.mv("/tmp/Sub.srt", @prefs["Directories"]["Download"]+@current.fichier+".srt")
				@cinema.setMovie_(OSX::QTMovie.movieWithFile(@prefs["Directories"]["Download"]+@current.fichier))
				@cinema.play(self)
			else
				@fenMovie.close()
			end
		end
	end
	ib_action :Tester

	def TestOK(sender)

		@cinema.pause(self)

		if File.exist?(@prefs["Directories"]["Download"]+@current.fichier+".srt")
			# Créer l'arbo si nécessaire
			CheckArbo()

			# Déplacement du film
			ext = @current.fichier.split('.').last
			if (@prefs["Subs management"]["Move"] == 0)
				FileUtils.cp(@prefs["Directories"]["Download"]+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
			else
				FileUtils.mv(@prefs["Directories"]["Download"]+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
			end

			# Déplacement du sous titre
			FileUtils.mv(@prefs["Directories"]["Download"]+@current.fichier+".srt", @current.repTarget+@current.fileTarget+".srt")

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
		if File.exist?(@prefs["Directories"]["Download"]+@current.fichier+".srt")
			FileUtils.rm(@prefs["Directories"]["Download"]+@current.fichier+".srt")
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
				FileUtils.mv("/tmp/Sub.srt", @prefs["Directories"]["Subtitles"]+@current.candidats[@plusmoins.intValue-1].fichier+".srt")
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
		if (@prefs["Subs management"]["Move"] == 0)
			FileUtils.cp(@prefs["Directories"]["Download"]+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
		else
			FileUtils.mv(@prefs["Directories"]["Download"]+@current.fichier, @current.repTarget+@current.fileTarget+".#{ext}")
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
		if @bCommande.state() == 1 then system(@prefs["Subs management"]["Commande"]) end
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
		
		@ovserie = @ligneslibrary[@listeseries.selectedRow()]
		@ovimage.setImage(@ovserie.image)
		
		# Remplissage du tableau et vérification du status
		@lignesinfos.clear()
		subsok = 0
		chargeok = 0
		for i in (0..@ovserie.nbepisodes-1)
			new_ligne = InfosSaison.new
			new_ligne.episode = @ovserie.episodes[i]["Episode"]
			new_ligne.titre = @ovserie.episodes[i]["Titre"]
			new_ligne.diffusion = @ovserie.episodes[i]["Diffusion"]
			new_ligne.telecharge = 0
			new_ligne.soustitre = 0

			temp1 = sprintf("s%02de%02d", @ovserie.saison, new_ligne.episode.to_i)
			temp2 = sprintf("%d%02d", @ovserie.saison, new_ligne.episode.to_i)
			temp3 = sprintf("%dx%02d", @ovserie.saison, new_ligne.episode.to_i)

			# Recherche de l'épisode
			for j in (0..@allEpisodes.size()-1)
				if @allEpisodes[j].fichier.downcase.match(@ovserie.serie.downcase) or @allEpisodes[j].fichier.downcase.match(@ovserie.serie.downcase.gsub(/ /, '.'))
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
			manageButtons("Library")
		else
			while @vue.subviews[0].frame.width > 227.0
				taille.width = 227.0
				@vue.subviews[0].setFrameSize_(taille)
				@vue.displayIfNeeded
			end
			@bCleanSerie.setHidden(true)
			@bWebSerie.setHidden(true)
			manageButtons("Episodes")
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
