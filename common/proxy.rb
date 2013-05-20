class Proxy
	attr_accessor :current_idx, :proxies

	def initialize
		self.proxies = []
		proxy_path = File.join(Common::PREF_PATH, "proxy.txt")
		if File.exists?(proxy_path)
			self.proxies = []
			File.read(proxy_path).split(/\s+/im).each do |txt|
				next if txt.blank?
				if (m = txt.match(/^([0-9\.\s]+):([0-9\s]+):([^:]+):([^:]+)$/i))
					# buyproxy format= ip:port:user:pass
					self.proxies << "http://#{m[3].gsub(/\s+/, '')}:#{m[4].gsub(/\s+/, '')}@#{m[1].gsub(/\s+/, '')}:#{m[2].gsub(/\s+/, '')}"
				else
					# format http://valid_url
					self.proxies << (txt.match(/^https?:/im) ? txt : "http://#{txt}")
				end
			end
			Tools.logger.debug "PROXY LIST: #{proxies.inspect}"
		end
	end

	def get_proxy
		# on retourne un nouveau proxy à chaque demande, en les parcourant dans l'ordre
		return nil if proxies.blank?
		res = begin
			if current_idx.blank?
				self.current_idx = 0
				self.proxies.first
			else
				self.current_idx += 1
				self.current_idx = 0 if (current_idx>=proxies.size) # restart from zero
				self.proxies[current_idx]
			end
		end
		res.blank? ? nil : URI.parse(res)
	end
end
