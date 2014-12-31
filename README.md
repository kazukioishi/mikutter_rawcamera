mikutter_rawcamera
================

# WHAT IS THIS??
mikutter内でImageMagickを利用してRAW現像+JPEG変換+Twitter用に縮小できるプラグインです。  
現在ImageMagickで読めるRAWファイル(ニコン、キャノン、ソニー製などの眼レフのRAW)に対応しております。  
作者はSONY製のNEX-5Nしか持っていないためARWでしか検証できておりません。

# 今後の課題
* ホワイトバランスが読めなかったりする(ImageMagick側の問題?)
* 簡易レタッチ機能の実装

# 依存gem
* rmagick(インストール方法については公式Wiki参照)
* twitter

# RMagickの導入
ImageMagickのRubyバインディングであるRMagickのインストールにはImageMagickのライブラリが必要になります。  
Windowsでも動きますが(動作確認済)導入が大変なので、上手くいかないなら素直にLightroom使いましょう。

# このプラグインの使い道
現像して即アップできるので撮って出ししたい人にはおすすめです。
