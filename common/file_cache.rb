module FileCache
  CACHE_PATH = "/tmp/subsmgr"

  module_function
  
  def get_srt(link, referer = nil)
    path = FileCache.get_srt(link, referer)
    FileUtils.cp(path, "/tmp/Sub.srt")
  end
    
  def get_zip(link, file, referer = nil)
    begin
      # Récupération du zip
      full_path = get_file(link, referer)

      # Extraction du zip
      if file == "None"
        # 1 seul fichier dans le zip
        system("/usr/bin/unzip -c -qq #{full_path} > /tmp/Sub.srt")
      else
        # Sélection du fichier dans le zip
        system("/usr/bin/unzip -c -qq #{full_path} '#{file}' > /tmp/Sub.srt")
      end
    rescue Exception => e
      $stderr.puts "# SubsMgr Error # get_zip [#{file}] : #{e.inspect}\n#{e.backtrace.join('\n')}"
      @current.comment = "Pb dans la récupération du zip"
    end
  end

  def get_file(source, referer = nil)
    FileUtils.mkdir_p(CACHE_PATH)

    begin
      # on fabrique un nom de fichier unique pour le garder en cache pendant toute la journée
      crc = Digest::MD5.hexdigest("#{source}-#{Time.now.strftime('%Y-%m-%d')}")
      full_path = File.join(CACHE_PATH, crc)

      unless (File.exists?(full_path) && File.size(full_path)>0)
        file = BROWSER.get(source, :referer => referer)
        File.open(full_path, "w") {|f| f.write(file.body)}
      end
      return full_path
    rescue URI::InvalidURIError => err
      # not a full url ?
      if !@retried
        uri = URI.parse(source)
        source = uri.merge(err.message.split(":").last.strip.gsub(' ', '%20')).to_s
        @retried = true
        retry # on recommence au debut mais avec l'url modifiée pour voir
      else
        # bah ca marche pas, donc on laisse raler
        raise err
      end
    end
  end

  def get_html(source, referer = nil)
    FileUtils.mkdir_p(CACHE_PATH)
    begin
      # on fabrique un nom de fichier unique pour le garder en cache pendant toute la journée
      crc = Digest::MD5.hexdigest("#{source}-#{Time.now.strftime('%Y-%m-%d')}")
      full_path = File.join(CACHE_PATH, crc)

      if (File.exists?(full_path) && File.size(full_path)>0)
        Nokogiri::HTML(open(full_path).read).root
      else
        file = BROWSER.get(source, :referer => referer)
        File.open(full_path, "w") {|f| f.write(file.body)}
        file.root
      end
    rescue URI::InvalidURIError => err
      # not a full url ?
      if !@retried
        uri = URI.parse(source)
        source = uri.merge(err.message.split(":").last.strip.gsub(' ', '%20')).to_s
        @retried = true
        retry # on recommence au debut mais avec l'url modifiée pour voir
      else
        # bah ca marche pas, donc on laisse raler
        raise err
      end
    end
  end

end
