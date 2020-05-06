td2mt.sh: tDiary generated HTML file to MovableType file Converter
==================================================================

Forked from https://github.com/nogajun/td2mt

[tDiary](http://www.tdiary.org/)が生成したHTMLファイルをMovableType形式/Markdown形式に変換します。

オリジナルの td2mt.sh に対し、以下の改変を加えました。

* tDiary が生成した HTML のチェックにおいて、何らかの影響 (文字化け？) でテキストと認識されず grep が効かない箇所があったので -a オプションを追加
* タイトルに付与したカテゴリーを CATEGORY として引き継ぐ設定を追加
* タイトルに日付が含まれない場合 (上述のケース) はアンカーから取得した日付を使用する処理を追加
* コメントの日付の変換を修正

また、以下のプログラムを追加しました。

* post_process.py: 生成したファイルの内部リンク書き換えや YouTube 埋め込みプレーヤーの URL 書き換えを行う後処理プログラム
* gen_redirection.py: 各ページのリダイレクトを羅列した CSV ファイルを作成するプログラム


有用なプログラムを公開してくださった [nogajun](https://github.com/nogajun) さんに感謝します。
