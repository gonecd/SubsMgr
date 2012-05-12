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
		# on charge les icones des plugins à partir de la defintion de chaque plugin
		Plugin::LIST.each do |k|
			@icone[k] = OSX::NSImage.alloc.initWithContentsOfFile_(File.join(path, Plugin.constantize(k)::ICONE))
		end
		@icone
	end
end
