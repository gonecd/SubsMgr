# encoding: utf-8
module Icones
	module_function
	def path=(new_value)
		@icone_path = new_value
	end
	
	def path
		@icone_path
	end
	
	def list
		return @icone if defined?(@icone)
		@icone = {}
		@icone["None"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "3D-TV_32x32.png"))
		@icone["NotAired"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "mire.jpg"))
		@icone["Aired"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "antenne2.png"))
		@icone["Subtitled"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "SubsMgr.icns"))
		@icone["TorrentLoaded"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "torrent.png"))
		@icone["VideoLoaded"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "test.png"))
		@icone["EpSpecial"] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, "special.png"))
		
		# on charge les icones des plugins en partant de la convention que l'icone d'un plugin
		# correspond à son nom en minuscule et que l'icone porte l'extension png
		Plugin::LIST.each do |source|
			kls = Plugin.constantize(source)
			full_path = File.join(path, "#{kls.field_name}.png")
			unless File.exists?(full_path)
				full_path = File.join(path, "default.png")
			end
			@icone[source] = OSX::NSImage.alloc.initWithContentsOfFile_(full_path)
		end
		@icone
	end
end
