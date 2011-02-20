class Plugin::MySource < Plugin::Base
	INDEX = 7
	ICONE = 'SubsMgr.icns'
	NAME = 'mysource'

	def get_from_source
		# generer le fichier /tmp/Subs.srt
	end
	
	def do_search
		# faire l'analyse et la recherche d'un épisode spécifique
	end
end