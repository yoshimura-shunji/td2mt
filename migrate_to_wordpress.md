
tDiaryからWordPressへデータを移行する
=====================================

td2mt.shを利用してtDiaryデータをWordPressへ移行する方法を説明します。
移行作業はLinux上の端末から行います。


td2mt.shの画像パス設定を変更する
--------------------------------

エディタでtd2mt.shを開き、tDiaryとWordPressの画像パスを設定します。
WordPressではwp-content以下に画像などを保存するので、tDiaryの画像をまとめたディレクトリを作って、そこに移行する日記の画像を置くと良いでしょう。

適当な場所にtd2mt.shをコピーし、テキストエディタで開きます。

    # tDiaryと移行先の画像パス(ファイル名除く)
    # DIARY〜にtDiaryの画像パス、POST〜に移行先のパスを指定する。
    # sedで置換するので文字によってはエスケープする必要がある
    #
    DIARY_IMAGE_PATH="\./images/"
    POST_IMAGE_PATH="\./wp-content/tdiary/"

冒頭にあるDIARY_IMAGE_PATHにtDiaryの画像パス、POST_IMAGE_PATHにWordPressの画像のパスを設定します。


squeeze.rbを利用してHTMLファイルの生成
---------------------------------------

tDiary contribに収録されている(5.0.0以前は本体付属)のsqueeze.rbを利用して、HTMLファイルを生成します。

    $ ruby (tDiary Contribディレクトリ)/plugin/squeeze.rb -p (tDiary本体ディレクトリ)/lib/ -c (tdiary.confのあるディレクトリ) (出力先ディレクトリ)

変換が終わると出力先ディレクトリに「(出力先ディレクトリ)/YYYY/MMDD」という形でHTMLが生成されます。


HTMLファイルからMT形式に変換
----------------------------

td2md.shを使って変換します。
変換を行う際、いきなり全部のファイルを変換すると時間もかかる上に変換ミスがわかりにくくなるので、1ファイルだけで試したり、1年分のみ変換をするなど少しずつ試した上で問題がないことを確認できれば、全部変換をするという手順で変換するとよいでしょう。

    $ find (HTMLのあるディレクトリ) -type f | sort | while read; do td2mt.sh $REPLY; done > export.txt


データをWordPressへインポートする
---------------------------------

変換したMovableType形式のファイルをWordPressへインポートします。

インポートは、WordPressにログインしてダッシュボードから、ツール→インポート→Movable Type and TypePadを開き、生成したファイルを指定して読み込むだけです。
取り込む数が多すぎて失敗する場合は、もう一度、読み込み直すとインポート済みの記事は飛ばしてインポートしてくれるので何度かリトライしてください。

### タグのインポートについて

MovableTypeインポーターではタグのインポートはサポートされていないので、タグも一緒にインポートするにはプラグインに手を加える必要があるようです。

* WordPress 3.0にMovable Typeのタグをインポートする: 小粋空間: http://www.koikikukan.com/archives/2010/07/20-013333.php


WordPressへ画像ファイルをアップロードする
----------------------------------------

td2md.shに設定したWordPressの画像ディレクトリに、tDiaryの画像ファイルをアップロードします。

アップロードしたなら、画像をWordPressに認識させるため「[Add From Server](https://wordpress.org/plugins/add-from-server/)」プラグインをインストールし、設置した画像を登録します。


コメントの移動(セクションを記事にした場合)
------------------------------------------

ここまでで間違いがなければ、移行した記事と画像は表示されるので、ざっくりと見て変換ミスや画像のリンクなどに異常がないか確認をします。

日記の1日を1記事にした場合は問題ありませんが、セクションを記事にした場合、記事とコメントの文脈がずれている場合があるので、おかしい部分を発見したなら、「[Tako Movable Comments](https://wordpress.org/plugins/tako-movable-comments/)」プラグインをインストールして、コメントを正しい記事の場所に移動します。


mod_rewriteを設定してtDiaryのURLをリダイレクトする
--------------------------------------------------

Apacheのmod_rewriteを利用して、tDiaryのYYYYMMDD.htmlへのアクセスをWordPressにリダイレクトします。

(検証中)


移行終了
--------

以上でWordPressへの移行は終了です。
他のCMSでも、大体似たような手順になると思います。
