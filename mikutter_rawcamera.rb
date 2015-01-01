# -*- coding: utf-8 -*-
require 'twitter'
require 'rmagick'

Plugin.create :mikutter_rawcamera do

  #Twitterアップロード関連
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

  #レタッチ機能
  class PicEditDialog
    attr_accessor :magickimage
    attr_accessor :yes_btn
    attr_accessor :no_btn
    attr_accessor :gtkimage
    attr_accessor :gtkrange
    attr_accessor :window
    attr_accessor :rangevalue

    def initialize(filepath)
      image = Magick::Image.read(filepath).first
      image.format = "JPEG"
      @magickimage = image.resize_to_fit(500,500)
      @rangevalue = 1.0
    end

    def convert_pixbuf(img)
      loader = Gdk::PixbufLoader.new
      loader.write(img.to_blob)
      loader.close
      return loader.pixbuf
    end

    def show
      @window = Gtk::Window.new
      @window.title = "簡易レタッチ(明度調整)"
      #@window.set_default_size(500,500)
      @yes_btn = Gtk::Button.new("送信")
      @no_btn = Gtk::Button.new("破棄")
      @gtkimage = Gtk::Image.new(convert_pixbuf(@magickimage))
      @gtkrange = Gtk::HScale.new
      @gtkrange.set_range(0, 5)
      @gtkrange.set_increments(0.1,0.1)
      @gtkrange.value = 1
      @gtkrange.signal_connect("value-changed") do |range|
        #数値変更
        @rangevalue = range.value
        newimage = @magickimage.modulate(range.value)
        newimage.format = "JPEG"
        @gtkimage.pixbuf = convert_pixbuf(newimage)
      end
      #pack
      hbox = Gtk::HBox.new(true, 0)
      hbox.pack_start(@yes_btn, true, true, 5)
      hbox.pack_start(@no_btn, true, true, 5)
      vbox = Gtk::VBox.new(false, 0)
      vbox.pack_start(@gtkrange,false,false,5)
      vbox.pack_start(@gtkimage, false, false, 5)
      vbox.pack_start(hbox, false, false, 5)
      @window.add(vbox)
      @window.show_all
    end

    def yes_clicked
      @yes_btn.signal_connect("clicked") do
        yield
      end
    end

    def no_clicked
      @no_btn.signal_connect("clicked") do
        yield
      end
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

      #クラッシュの原因のため一時的に削除
      # preview = Gtk::Image.new
      # dialog.preview_widget = preview
      # dialog.signal_connect("update-preview") {
      #   filename = dialog.preview_filename
      #   if filename
      #     unless File.directory?(filename) && !File.exists?(filename)
      #       orig = Magick::Image.read(filename).first
      #       orig.format = "JPEG"
      #       thumb = orig.resize_to_fit(100,100)
      #       thumb.format = "JPEG"
      #       loader = Gdk::PixbufLoader.new
      #       loader.write(thumb.to_blob)
      #       loader.close
      #       #Free!-Eternal Memoryleak-
      #       orig.destroy!
      #       thumb.destroy!
      #       pixbuf = loader.pixbuf.dup
      #       preview.set_pixbuf(pixbuf)
      #       dialog.set_preview_widget_active(true)
      #     else
      #       dialog.set_preview_widget_active(false)
      #     end
      #   else
      #     dialog.set_preview_widget_active(false)
      #   end
      # }

      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        filename = dialog.filename.to_s
        puts filename
      else
        filename = nil
      end
      dialog.destroy

      if filename
        diag = PicEditDialog.new(filename)
        diag.show
        diag.yes_clicked do
          #ダイアログを消す
          value = diag.rangevalue
          diag.window.destroy
          message = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
          Thread.new {
            basedir = File.join(ENV["HOME"], ".mikutter/tmp")
            tmpimagepath = File.join(basedir, rand(100000).to_s + ".jpg")
            puts tmpimagepath
            #load file
            img = Magick::Image.read(filename).first
            img.format = "JPEG"
            img2 = img.resize_to_fit(1920,1080)
            puts value
            img2 = img2.modulate(value)
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

        diag.no_clicked do
          diag.window.destroy
        end
      end

    rescue Exception => e
      Plugin.call(:update, nil, [Message.new(message: e.to_s, system: true)])
    end
  end

end
