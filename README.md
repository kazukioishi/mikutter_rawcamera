mikutter_rawcamera
================

# WHAT IS THIS??
mikutter内でImageMagickを利用してRAW現像+簡易レタッチ+JPEG変換+Twitter用に縮小できるプラグインです。  
現在ImageMagickで読めるRAWファイル(ニコン、キャノン、ソニー製などの眼レフのRAW)に対応しております。  

# 今後の課題
* ホワイトバランスが読めなかったりする(ImageMagick側の問題?)
* ファイル選択画面での画像プレビューの高速化(現状不安定なため無効化)

# 動作確認済み環境
OS: Windows 8.1 + Ruby(32bit)  
カメラ: NEX-5N(記録方式はARW)

# 依存gem
* rmagick(インストール方法については公式Wiki参照)
* twitter

# RMagickの導入
ImageMagickのRubyバインディングであるRMagickのインストールにはImageMagickのライブラリが必要になります。  
Windowsでも動きますが(動作確認済)導入が大変なので、上手くいかないなら素直にLightroom使いましょう。

# このプラグインの使い道
現像して即アップできるので撮って出ししたい人にはおすすめです。

# このプラグインで出力した画像の例
![テスト画像](https://raw.githubusercontent.com/kazukioishi/mikutter_rawcamera/master/demo_compressed.jpg "レイヤーさん")
