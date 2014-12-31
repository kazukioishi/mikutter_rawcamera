# -*- coding: utf-8 -*-
require 'twitter'
require 'rmagick'

Plugin.create :mikutter_rawcamera do

  @clients = {}

  unless UserConfig[:twitter_secret] # mikutter >= 3.0.0
    @clients[Service.primary.idname] = Twitter::REST::Client.new do |c|
      c.consumer_key       = Service.primary.twitter.consumer_key
      c.consumer_secret    = Service.primary.twitter.consumer_secret
      c.oauth_token        = Service.primary.twitter.a_token
      c.oauth_token_secret = Service.primary.twitter.a_secret
    end
  else # mikutter < 3.0.0
    if defined? Twitter::REST
      @clients[Service.primary.idname] = Twitter::REST::Client.new do |c|
        c.consumer_key       = CHIConfig::TWITTER_CONSUMER_KEY
        c.consumer_secret    = CHIConfig::TWITTER_CONSUMER_SECRET
        c.oauth_token        = UserConfig[:twitter_token]
        c.oauth_token_secret = UserConfig[:twitter_secret]
      end
    else
      Twitter.configure do |c|
        c.consumer_key       = CHIConfig::TWITTER_CONSUMER_KEY
        c.consumer_secret    = CHIConfig::TWITTER_CONSUMER_SECRET
        c.oauth_token        = UserConfig[:twitter_token]
        c.oauth_token_secret = UserConfig[:twitter_secret]
      end
      @clients[Service.primary.idname] = Twitter.client
    end
  end

  command(:update_with_raw,
  name: 'RAW現像して投稿する',
  condition: lambda{ |opt| true },
  visible: true,
  role: :postbox) do |opt|
    begin

      dialog = Gtk::FileChooserDialog.new("Select Upload Image",
      nil,
      Gtk::FileChooser::ACTION_OPEN,
      nil,
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])

      filter = Gtk::FileFilter.new
      filter.name = "Image Files"
      #SONY
      filter.add_pattern('*.arw')
      filter.add_pattern('*.ARW')
      #CANON
      filter.add_pattern('*.cr2')
      filter.add_pattern('*.CR2')
      #CANON
      filter.add_pattern('*.crw')
      filter.add_pattern('*.CRW')
      #KODAK
      filter.add_pattern('*.dcr')
      filter.add_pattern('*.DCR')
      #KODAK
      filter.add_pattern('*.k25')
      filter.add_pattern('*.K25')
      #KODAK
      filter.add_pattern('*.kdc')
      filter.add_pattern('*.KDC')
      #SONY
      filter.add_pattern('*.mrw')
      filter.add_pattern('*.MRW')
      #NIKON
      filter.add_pattern('*.nef')
      filter.add_pattern('*.NEF')
      #NIKON
      filter.add_pattern('*.nrw')
      filter.add_pattern('*.NRW')
      #OLYMPUS
      filter.add_pattern('*.orf')
      filter.add_pattern('*.ORF')
      #RAW
      filter.add_pattern('*.raw')
      filter.add_pattern('*.RAW')
      #Panasonic
      filter.add_pattern('*.rw2')
      filter.add_pattern('*.RW2')
      #SONY
      filter.add_pattern('*.SR2')
      filter.add_pattern('*.sr2')
      filter.add_pattern('*.srf')
      filter.add_pattern('*.SRF')
      dialog.add_filter(filter)

      preview = Gtk::Image.new
      dialog.preview_widget = preview
      dialog.signal_connect("update-preview") {
        filename = dialog.preview_filename
        if filename
          unless File.directory?(filename)
            orig = Magick::Image.read(filename).first
            orig.format = "JPEG"
            thumb = orig.resize_to_fit(100,100)
            thumb.format = "JPEG"
            loader = Gdk::PixbufLoader.new
            loader.write(thumb.to_blob)
            loader.close
            #Free!-Eternal Memoryleak-
            thumb.destroy!
            pixbuf = loader.pixbuf.dup
            preview.set_pixbuf(pixbuf)
            dialog.set_preview_widget_active(true)
          else
            dialog.set_preview_widget_active(false)
          end
        else
          dialog.set_preview_widget_active(false)
        end
      }

      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        filename = dialog.filename.to_s
        puts filename
      else
        filename = nil
      end
      dialog.destroy

      if filename
        message = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
        Thread.new {
          basedir = File.join(ENV["HOME"], ".mikutter/tmp")
          tmpimagepath = File.join(basedir, rand(100000).to_s + ".jpg")
          puts tmpimagepath
          #load file
          img = Magick::Image.read(filename).first
          img.format = "JPEG"
          img2 = img.resize_to_fit(1920,1080)
          img2.format = "JPEG"
          #tmpimage
          img2.write(tmpimagepath) { self.quality = 100 }
          #Free!-Eternal Memoryleak-
          img.destroy!
          img2.destroy!
          #ニコニコニコ～ｗ
          OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
          @clients[Service.primary.idname].update_with_media(message, File.new(tmpimagepath))
          File.delete(tmpimagepath)
        }
        Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ''
      end

    rescue Exception => e
      Plugin.call(:update, nil, [Message.new(message: e.to_s, system: true)])
    end
  end

end
