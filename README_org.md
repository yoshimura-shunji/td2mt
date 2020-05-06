
td2mt.sh: tDiary generated HTML file to MovableType file Converter
==================================================================

[tDiary](http://www.tdiary.org/)が生成したHTMLファイルをMovableType形式/Markdown形式に変換します。


これはなに?
-----------

このツールは、tDiaryの日記を各種CMSにインポートするためのMovableType形式/Markdown形式に変換するためのツールです。

変換の仕組みとしては、日記データから直接の変換をおこなうのではなく、tDiaryから出力されたHTMLファイルからMobableType形式/Markdown形式のファイルを生成します。


必要なツール
------------

- GNU bash
- GNU sed
- xmllint
- pandoc

Linux環境での利用を想定しています。MacやWindows環境での利用は想定していませんが、GNU関係のツールはすぐに揃うと思います。

xmllintとpandocについては別途インストールをする必要があるので、Debian/Ubuntuの場合、aptを使ってインストールしてください。

    $ sudo apt-get install libxml2-utils pandoc


利用方法
--------

具体的な利用例については「[tDiaryからWordpressに移行する](migrate_to_wordpress.md)」をご覧ください。

    Usage: td2mt.sh [オプション] [tDiary HTML ファイル]

    Options:
        -s: セクションを記事として出力
            (デフォルト: 1日を記事として出力)
        -m: 1日を記事としてMarkdown形式で出力
        -h: ヘルプを表示

ファイルには、tDiaryの1日表示(http://(tDiary URL)/?date=YYYYMMDD)で表示されるHTMLファイルを指定します。

標準では日記の1日を1記事として変換しますが、日記内のセクションを1記事として分割、変換をする場合は「-s」オプションを使用します。

セクションを1記事として変換する場合の制約としては、「セクション見出しがタイトルとして利用され、その日のタイトルが利用されない」「コメントがその日の最後の記事にまとめられる(記事とコメントの文脈がつながらない)」があります。

変換された記事は標準出力に出力されるので、ファイルとして保存する場合はリダイレクトを利用します。

    $ ./td2md.sh (tDiaryのHTML) > export.txt

複数のファイルを指定する場合は、このような形で実行するとよいでしょう。

    $ find (HTMLファイルのあるディレクトリ) -type f | sort | while read;do ./td2mt.sh $REPLY; done > export.txt

Markdown形式に変換する場合には「iframeが消える」という制約があります。これは使用しているpandocの制限によるもので、現時点では対処できないのでご了承ください。



### 著者名や投稿時間、画像パス書き換え設定

スクリプトファイルを開いて冒頭にある変数を設定することにより、変換時に著者名、投稿時間や移行先の画像パスが変更できます。コメントを参考に適宜、変更してください。

    # 著者名と投稿時間
    # AUTHORに著者名、TIMEに投稿時間を設定
    #
    POST_AUTHOR=""
    POST_TIME="12:00:00"

    # コメントやステータスなど
    # コメント許可や行末、公開ステータスを指定する。意味はMTのドキュメントを参照
    # http://www.movabletype.jp/documentation/mt6/tools/import-export-format.html
    #
    POST_ALLOW_COMMENTS="1"
    POST_CONVERT_BREAKS="0"
    POST_STATUS="Publish"

    # tDiaryと移行先の画像パス(ファイル名除く)
    # DIARY〜にtDiaryの画像パス、POST〜に移行先のパスを指定する。
    # sedで置換するので文字によってはエスケープする必要がある
    #
    DIARY_IMAGE_PATH="\./images/"
    POST_IMAGE_PATH="\./wp-content/uploads/tdiary/"


制限事項など
-----------

変換の仕組みとしては、xmllintを使って必要な部分を抜き出し、sedで不要な部分を削るという単純な事をしているだけです。そのため、条件にマッチしないとすり抜けてしまいます。
うまく変換できない場合は、以下の点をチェックしてください。

- ヘッダ、フッターやプラグインは必要最低限にしてください
- 日付などの表示はデフォルト状態にしてください
- category_to_tag.rbプラグインを有効にしてください

デフォルトの状態を想定して作ってあるので、変換する際のHTMLはシンプルなほうがトラブルは少ないと思います。

タグの抽出については、category_to_tagプラグインで出力されたタグから変換しているのでプラグインを有効にしておいてください。

- tDiary記法が多い場合は、セクションを1記事にしない
- Blogkitでは、セクションを1記事は使えません

tDiary記法は、ユーザーが意図したとおりに書くことが難しい記法で、意図と違う形でHTMLが出力されている場合があります。その状態でセクションごとに記事を分割すると、よくわからない形で分割されてしまうので、tDiary記法で書いた日記があるかたはデフォルトの1日1記事の形を利用すると良いでしょう。

Blogkitを使用している方は、Blogkitで出力されるHTMLにはセクション自体が無いのでセクションを1記事にすることはできません。

Markdown形式での出力では、ifram部分が消えます。これは、pandoc自体の制限によるものです。


最後に
------

このツールはとても稚拙で原始的です。
元のデータから生成するような形で、誰かがきちんと書き直してくれるとうれしく思います。


License
-------

CC0 1.0 Universal 

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png "CC0")](http://creativecommons.org/publicdomain/zero/1.0/deed.ja)

