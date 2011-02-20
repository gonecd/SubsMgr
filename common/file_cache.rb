require 'tempfile'

class CacheSub
	attr_accessor :root_path
	
	def initialize(root_path)
		self.root_path = root_path
		FileUtils.mkdir_p(root_path) unless root_path.blank?
		self
	end
	
	def write(entry, content)
		path = full_path(entry)
		File.open(path, "w") {|f| f.write(content)}
	end
	
	def read(entry)
		open(full_path(entry)).read if exists?(entry)
	end
	
	def key(source)
		Digest::MD5.hexdigest("#{source}-#{Time.now.strftime('%Y-%m-%d')}")
	end

	def exists?(entry)
		path = full_path(entry)
		File.exists?(path) && File.size(path)>0 && File.ctime(path)>=1.days.ago
	end

	def full_path(entry)
		File.join(root_path, entry)
	end

end

module FileCache
	CACHE_PATH = "/tmp/subsmgr"

	BROWSER = Mechanize.new { |agent|
		agent.user_agent_alias = 'Mac Safari'
		agent.follow_meta_refresh = false
	}

	module_function

	def cache
		@cache_store ||= CacheSub.new(CACHE_PATH)
	end
	
	# recuperer un sous titre non compressé
	def get_srt(link, referer = nil)
		path = get_file(link, :referer => referer)
		FileUtils.cp(path, "/tmp/Sub.srt")
	end

	# recuperer un zip contenant le bon sous titre
	def get_zip(link, file, referer = nil)
		begin
			# Récupération du zip
			full_path = get_file(link, :refered => referer, :zip => true)

			# Extraction du zip
			if file == "None"
				# 1 seul fichier dans le zip
				system("/usr/bin/unzip -c -qq #{full_path} > /tmp/Sub.srt")
			else
				# Sélection du fichier dans le zip
				system("/usr/bin/unzip -c -qq #{full_path} '#{file}' > /tmp/Sub.srt")
			end
		rescue Exception => e
			$stderr.puts "# SubsMgr Error # get_zip [#{file}] : #{e.inspect}\n#{e.backtrace.join('\n')}"
			@current.comment = "Pb dans la récupération du zip"
		end
	end

	#FIXME: inclure la gestion des fichiers rar pour les convertir en fichier zip car parfois, on recupère des rar
	def flatten_archive(archive_path)
		if `zipinfo -1 #{archive_path} |grep ".zip"|wc -l`.strip.to_i>0
			tmp = Tempfile.new("unzip")
			path = tmp.path
			File.unlink(path)
			# unzip
			cmd <<-EOF
			mkdir -p #{path};
			unzip -j -o -qq #{archive_path} -d #{path}/; 
			find #{path} -name \"*.zip\" -exec unzip -j -o {} -d #{path}/ \\; -exec rm {} \\; ;
			cd #{path}; 
			zip -rj #{archive_path}.new .; 
			mv #{archive_path}.new #{archive_path}
			EOF
			system cmd.strip.gsub(/\n+/im, ' ')
			FileUtils.rm_rf(path)
		end
		archive_path
	end

	# recuperer un fichier quelconque
	# options:
	# :zip => true pour decompresser recursivement le zip si necessaire et retourne un zip "a plat"
	# :referer => url de referer a emuler
	# :path => chemin complet du stockage du fichier si c'est à conserver ailleurs (et dans ce cas, les repertoires doivent deja exister)
	def get_file(source, options = {})
		FileUtils.mkdir_p(CACHE_PATH)
		# on fabrique un nom de fichier unique pour le garder en cache pendant toute la journée
		crc = cache.key(source)
		path = cache.full_path(crc)
		if cache.exists?(crc)
			Tools.logger.debug("# SubsMgr info - Load #{source} from cache")
		else
			Tools.logger.debug("# SubsMgr info - Get #{source}")
			file = BROWSER.get(source, :referer => options[:referer])
			cache.write(crc, file.body)
			flatten_archive(path) if options[:zip]
		end
		path
	end

	def get_html(source, options = {})
		# options:
		# +referer+ : préciser un referer pour tromper d'eventuelle vérification sur le serveur
		# +xml+: ajouter :xml => true si la page demandée est une page XML
		FileUtils.mkdir_p(CACHE_PATH)
		# on fabrique un nom de fichier unique pour le garder en cache pendant toute la journée
		crc = cache.key(source)
		if cache.exists?(crc)
			options[:xml] ? Nokogiri::XML(cache.read(crc)).root : Nokogiri::HTML(cache.read(crc)).root
		else
			file = BROWSER.get(source, :referer => options[:refered])
			cache.write(crc, file.body.to_s)
			options[:xml] ? Nokogiri::XML(file.body.to_s).root : file.root
		end
	end

end
