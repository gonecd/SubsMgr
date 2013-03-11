class Banner
	
	def initialize(root_dir)
		# Initialisation des banières de séries
		@root_dir = root_dir
		@seriesBanners = @series = {}
		load_plist
		cleanup_banners
		set_banners
	end
	
	# recupere, stocke, et retourne l'image de la serie 
	def retrieve_for(myserie)
		myserie = myserie.downcase
		path = banner_path(myserie)
		if path && File.exists?(path) && (File.size(path)>100)
			@seriesBanners[myserie] ||= OSX::NSImage.alloc.initWithContentsOfFile_(path)
		else
			# Recherche sur TheTVdb
			monURL = "http://www.thetvdb.com/api/GetSeries.php?seriesname=#{myserie.gsub(/ /, '+')}"
			doc = FileCache.get_html(monURL, :xml => true)
			blk = doc.search("Series").detect do |k|
				k.search("SeriesName").inner_html.to_s.downcase == myserie
			end
			
			if blk
				# on memorise les paramètres de la banniere
				@series[myserie] = {"Id" => blk.search("seriesid").inner_html.downcase, "Banner" => "#{myserie.downcase}.jpg"}
				@series.save_plist("#{Common::PREF_PATH}/SubsMgrSeries.plist")

				# On loade la bannière sur theTVdb
				linkBanner = blk.search("banner").inner_html.to_s.downcase
				path = banner_path(myserie)
				FileUtils.cp(FileCache.get_file("http://www.thetvdb.com/banners/#{linkBanner}"), path)
				@seriesBanners[myserie] ||= OSX::NSImage.alloc.initWithContentsOfFile_(path)
			else
				Icones.list["None"]
			end
		end
	end
	
	def id_for(myserie)
		@series[myserie.to_s.downcase] ? @series[myserie.to_s.downcase]['Id'].to_i : 0
	end

	private
	
	def plist_path
		File.join(Common::PREF_PATH, "SubsMgrSeries.plist")
	end

	def load_plist
		@series = Plist::parse_xml(plist_path)
	end

	def save_plist
		@series.save_plist(plist_path)
	end

	def set_banners
		@series.each do |serie|
			retrieve_for(serie[0])
		end
	end

	def cleanup_banners
		# on nettoye la base des doublons eventuels liés aux problemes de case
		cleaned = false
		@series.each do |k, v|
			if (k != k.downcase)
				@series[k.downcase] = v
				@series.delete(k)
				cleaned = true
			elsif (v['Banner'] != v['Banner'].downcase)
				@series[k]['Banner'] = v['Banner'].downcase
				cleaned = true
			end
		end
		save_plist if cleaned
	end
	
	def banner_path(myserie)
		myserie = myserie.downcase
		if @series[myserie] && @series[myserie]["Banner"]
			File.join(@root_dir, @series[myserie]["Banner"].to_s.downcase)
		end
	end

end
