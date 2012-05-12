# encoding: utf-8
# Structure d'insertion dans la liste
class Ligne < CommonStruct
	attr_accessor :fichier, :date, :conf, :comment
	attr_accessor :serie, :saison, :episode, :team, :format, :source, :provider, :titre, :infos
	attr_accessor :repTarget, :fileTarget
	attr_accessor :status, :candidats
	
	# on sait pas trop pourquoi, mais il faut un accessor par plugin, portant le nom
	# du plugin => sinon ca fait planter l'interface de Cyril, même s'il ne sait pas pourquoi
	Plugin::LIST.each do |k|
		attr_accessor k.downcase.to_sym
	end
	
	def initialize(*args)
		self.comment = ""
		self.conf = 0
		self.candidats = []
		reset!
		super
	end
	
	def reset!
		self.candidats.clear if self.candidats.size>0
		init_with('-')
	end
	
	def processed!
		self.status = "Traité"
		init_with("")
	end
	
	def pending!
		self.status = "Attente"
		self.comment = ""
		self.mysource = ""
		self.conf = 0
		init_with("")
	end
	
	def to_s
		"<Ligne serie:#{serie} - saison: #{saison} - episode: #{episode} - team:#{team} - format: #{format}>"
	end
	
	private
	def init_with(val)
		self.forom = self.seriessub = self.podnapisi = self.tvsubs = self.tvsubtitles = self.soustitreseu = self.mysource = self.local = val
	end

end
