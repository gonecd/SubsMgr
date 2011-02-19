# ------------------------------------------
# Constantes
# ------------------------------------------
BROWSER = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
  agent.follow_meta_refresh = false
}

# ------------------------------------------
# Structures de gestion
# ------------------------------------------

class CommonStruct
  # on met en place la possibilité d'initialiser une structure via
  # Structure.new(:key1 => val1, :key2 => val2, ...)
  def initialize(options = {})
    options.each do |k,v|
      self.send("#{k}=", v) if self.respond_to?(k)
    end
  end
end

# ------------------------------------------
# Structures de gestion
# ------------------------------------------


# Structure d'insertion dans la liste
class Ligne < CommonStruct
  attr_accessor :fichier, :date, :conf, :comment
  attr_accessor :serie, :saison, :episode, :team, :format, :source, :provider, :titre, :infos
  attr_accessor :repTarget, :fileTarget
  attr_accessor :forom, :seriessub, :podnapisi, :tvsubs, :tvsubtitles, :local, :mysource, :soustitreseu
  attr_accessor :status, :candidats
end

# Structure de gestion des sous titres trouvés (candidats)
class WebSub < CommonStruct
  attr_accessor :fichier, :date, :lien, :confiant, :source, :referer

  def to_s
    "#{fichier} - #{date} - #{lien} - #{confiant}"
  end
end

# Structure d'insertion dans la liste des séries
class Series < CommonStruct
  attr_accessor :nom, :image, :idtvdb
  
  def to_s
    "#{nom} - #{idtvdb}"
  end
end

# Structure d'insertion dans la Librairie
class Library < CommonStruct
  attr_accessor :serie, :saison, :status, :URLTVdb, :nbepisodes, :firstep, :lastep, :image, :episodes

  def to_s
    "#{serie} - #{saison} - #{status} - #{nbepisodes}"
  end
end

# Structure d'insertion dans les stats
class Stats < CommonStruct
  attr_accessor :source, :image, :search, :stime, :sfound, :smark, :process, :ptime, :pratio, :pauto
  attr_accessor :TimeSearch, :TimeProcess, :NbFound, :TotalMarks, :NbAuto
end

# Structure d'insertion dans les sources
class Sources < CommonStruct
  attr_accessor :source, :image, :active, :rank

  def to_s
    "#{source} - #{active} - #{rank}"
  end
end

# Structure de gestion pour les infos d'une saison
class InfosSaison < CommonStruct
  attr_accessor :episode, :titre, :diffusion, :telecharge, :soustitre
  
  def to_s
    "#{episode} - #{titre} - #{diffusion}"
  end
end


class Hash

  def deep_merge(hash)
    target = dup

    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end

      target[key] = hash[key]
    end

    target
  end

end
