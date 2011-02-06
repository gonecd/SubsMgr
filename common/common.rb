# ------------------------------------------
# External libs
# ------------------------------------------
if (rvm = `$HOME/.rvm/bin/rvm gemdir`.strip) != ''
  # lorsqu'on utilise rvm, les gems ne sont pas forcement trouvé donc on force le chemin des gems
  ENV['GEM_HOME'] = rvm
  require 'rubygems'
  Gem.clear_paths
else
  require 'rubygems'
end

require 'open-uri'
require 'cgi'
require 'csv'
require 'fileutils'
require 'mechanize'

# ------------------------------------------
# Common definitions
# ------------------------------------------
require 'structures.rb'
require 'file_cache'
require 'icones'
require 'statistics'

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
