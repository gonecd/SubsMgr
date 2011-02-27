#!/usr/bin/env ruby

base_path = File.expand_path(File.join(File.dirname(__FILE__), '../'))

$LOAD_PATH << File.join(base_path, "lib")
$LOAD_PATH << File.join(base_path, "lib/plist")

require 'plist'
require 'fileutils'

begin
	pref = Plist::parse_xml(File.join(ENV['HOME'], "Library/Application\ Support/SubsMgr/SubsMgrPrefs.plist"))
	dest = pref["Directories"]["Download"].to_s
	raise StandardError.new("Répertoire à traiter non précisé") if dest == ''

	FileUtils.cp_r Dir.glob("#{base_path}/test/torrents/*"), dest #, :verbose => true
	puts "Playground initialized ..."
rescue StandardError => err
	puts "ERROR: #{err.inspect}"
	puts "Avez-vous configuré les répertoires de subsmgr?"
end
