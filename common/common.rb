# ------------------------------------------
# External libs
# ------------------------------------------
if (rvm = `$HOME/.rvm/bin/rvm gemdir 2>/dev/null`.strip) != ''
	# lorsqu'on utilise rvm, les gems ne sont pas forcement trouvé donc on force le chemin des gems
	ENV['GEM_HOME'] = rvm
end
vendored = File.expand_path(File.join(File.dirname(__FILE__), "../vendor/bundle/ruby/1.8"))
$LOAD_PATH << "#{vendored}/gems/bundler-1.0.10/lib"

require 'rubygems'
ENV['GEM_PATH'] = vendored + (ENV['GEM_PATH'] ? ":#{ENV['GEM_PATH']}" : '')
Gem.clear_paths

require	 "bundler/setup"

require 'open-uri'
require 'cgi'
require 'csv'
require 'fileutils'
require 'mechanize'
require 'active_support/all'

# ------------------------------------------
# Common definitions
# ------------------------------------------
require 'structures'
require 'web_sub'
require 'file_cache'
require 'icones'
require 'statistics'
require 'tools'

# ------------------------------------------
# Sources managers
# ------------------------------------------
require 'plugin'
require 'series_sub'
require 'forom'
require 'local'
require 'my_source'
require 'podnapisi'
require 'sous_titres_eu'
require 'tv_subs'
require 'tv_subtitles'


# ------------------------------------------
# Common tools
# ------------------------------------------
module Common
	
	module_function
	def strip_tags(txt)
		txt.gsub(/<\/?[^>]+>/im, '')
	end
end
