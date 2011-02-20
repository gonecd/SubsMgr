#!/usr/bin/env ruby
frameworks = %w(libexslt.0.dylib libxslt.1.dylib libxml2.2.dylib libiconv.2.dylib libz.1.dylib)
nokorigi_version = '1.4.4'
oldpath = "/opt/local/lib"
newpath = "@executable_path/../Frameworks" 

target = File.expand_path(File.join(File.dirname(__FILE__), "../frameworks"))
frameworks.each do |from|
	frameworks.each do |change|
		puts "install_name_tool -change #{oldpath}/#{change} #{newpath}/#{change} #{target}/#{from}\n"
		system("install_name_tool -change #{oldpath}/#{change} #{newpath}/#{change} #{target}/#{from}")
	end
	system("otool -L #{target}/#{from}")
end

target = File.expand_path(File.join(File.dirname(__FILE__), "../vendor/bundle/ruby/1.8/gems/nokogiri-#{nokorigi_version}/lib/nokogiri/nokogiri.bundle"))
frameworks.each do |from|
	system("install_name_tool -change #{oldpath}/#{from} #{newpath}/#{from} #{target}")
	system("otool -L #{target}")
end

