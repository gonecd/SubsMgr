# encoding: utf-8
# ------------------------------------------
# External libs
# ------------------------------------------
if (rvm = `$HOME/.rvm/bin/rvm gemdir 2>/dev/null`.strip) != ''
	# lorsqu'on utilise rvm, les gems ne sont pas forcement trouvé donc on force le chemin des gems
	ENV['GEM_HOME'] = rvm
end
vendored = File.expand_path(File.join(File.dirname(__FILE__), "../vendor/bundle/ruby/1.8"))
$LOAD_PATH << "#{vendored}/gems/bundler-1.1.3/lib"

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
# Common tools
# ------------------------------------------
module Common
	PREF_PATH = File.join(ENV['HOME'], "Library/Application\ Support/SubsMgr")
	
	module_function
	def strip_tags(txt)
		txt.gsub(/<\/?[^>]+>/im, '')
	end
end

# ------------------------------------------
# Common definitions
# ------------------------------------------
require 'tools'
require 'structures'
require 'plugin'
require 'web_sub'
require 'ligne'
require 'proxy'
require 'file_cache'
require 'icones'
require 'banner'
require 'statistics'

# ------------------------------------------
# Sources managers: chargement dynamique
# ------------------------------------------
Dir.glob(File.expand_path(File.dirname(__FILE__) + "/../plugin/*.rb")).each do |f|
	name = f.split('/').last.gsub('.rb', '')
	next if name == 'plugin'
	require name
end

