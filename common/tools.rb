module Tools
	module_function
	# fonction pour logger les erreurs, on change le niveau de "verbosité" via l'intruction
	# Tools.logger.level = 0 à 3, avec 0: debug, 1: info, 2, warning, 3: erreur
	def logger
		unless defined?(@logger)
			@logger = Logger.new($stderr)
			@logger.level = 0
		end
		@logger
	end
end