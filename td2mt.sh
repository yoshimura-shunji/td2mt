#!/bin/bash
#
# td2mt.sh: tDiary Genarated HTML File to MovableType format Converter
# Copywrite (c) 2016 Jun NOGATA <nogajun+github@gmail.com>
#
# These codes are licensed under CC0.
# http://creativecommons.org/publicdomain/zero/1.0/deed.ja
#
#

set -e

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

# https://hexo.io/docs/front-matter.html
MARKDOWN_POST_ALLOW_COMMENTS="true"
MARKDOWN_FLAVOUR="markdown_github"

# tDiaryと移行先の画像パス(ファイル名除く)
# DIARY〜にtDiaryの画像パス、POST〜に移行先のパスを指定する。
# sedで置換するので文字によってはエスケープする必要がある
#
DIARY_IMAGE_PATH="\./images/"
POST_IMAGE_PATH="\./wp-content/tdiary/"

# ------------------------------------------------------

VERSION=0.1

usage(){
cat << _EOT_

$(basename ${0}) ${VERSION} is tDiary Genarated HTML File to MovableType format Converter

  Usage: $(basename ${0}) [OPTION] [tDiary HTML file]

  Options:
    -m: Output Markdown file
    -s: Output Diary section as a post
        (Default: Diary Day as a post)
    -h: Display the help and exit

_EOT_
exit 1
}

# xmllintのチェック
if [ ! "$(which xmllint)" ]; then
	cat << _EOT_ 1>&2
$(basename ${0}): xmllint Can't Found
  Please Install libxml2-utils Package(Debian/Ubuntu).
  \$ sudo apt-get install libxml2-utils

_EOT_
	exit 1
fi

XMLLINT="$(which xmllint) --html --nowrap --format --xpath"

# pandocのチェック
if [ ! "$(which pandoc)" ]; then
	cat << _EOT_ 1>&2
$(basename ${0}): pandoc Can't Found
  Please Install pandoc Package(Debian/Ubuntu).
  \$ sudo apt-get install pandoc

_EOT_
	exit 1
fi

PANDOC="$(which pandoc) -t ${MARKDOWN_FLAVOUR}+ignore_line_breaks -f html --wrap=none"

# pandocのチェック
if [ ! "$(which pandoc)" ]; then
	cat << _EOT_ 1>&2
$(basename ${0}): pandoc Can't Found
  Please Install pandoc Package(Debian/Ubuntu).
  \$ sudo apt-get install pandoc

_EOT_
	exit 1
fi

PANDOC="$(which pandoc) -t ${MARKDOWN_FLAVOUR}+ignore_line_breaks -f html --wrap=none"

# 引数がない場合
[ "$#" = "0" ] && usage

OUT_SWITCH=""

while getopts mslh OPT; do
	case $OPT in
        m) OUT_SWITCH="markdown"
            ;;
		s) OUT_SWITCH="section"
			;;
		h) usage
			;;
		*) usage
			;;
	esac
done

shift $((OPTIND - 1))

readonly PAGE=$1

# tDiaryが生成したHTMLのチェック 
if [ -z "$(grep -a 'name="generator"' "$PAGE" | grep tDiary)" ]; then
	echo "$(basename ${0}): ${PAGE}: It is not the tDiary Generated HTML file." 1>&2
	exit 1
fi

# ------------------------------------------------------

metadata(){
	cat << _EOT_
AUTHOR: $POST_AUTHOR
TITLE: $POST_TITLE
STATUS: $POST_STATUS
ALLOW COMMENTS: $POST_ALLOW_COMMENTS
CONVERT BREAKS: $POST_CONVERT_BREAKS
DATE: $POST_DATE
TAGS: $POST_TAGS
_EOT_
	for CATEGORY in "${CATEGORY_ARR[@]}";
	do
	        echo CATEGORY: $CATEGORY
	done
	echo "-----"
}

body(){
	cat << _EOT_
BODY:
${POST_BODY}
-----
_EOT_
}

comment(){
	cat << _EOT_
COMMENT:
AUTHOR: ${COMMENT_AUTHOR}
DATE: ${COMMENT_DATE}
${COMMENT_BODY}
-----
_EOT_
}

pingback(){
	cat << _EOT_
PING:
TITLE: ${COMMENT_TITLE}
URL: ${COMMENT_URL}
DATE: ${COMMENT_DATE}
${COMMENT_BODY}
-----
_EOT_
}

md_frontmatter(){
        cat << _EOT_
---
title: $POST_TITLE
date: $POST_DATE
author: $POST_AUTHOR
comments: $MARKDOWN_POST_ALLOW_COMMENTS
tags:
$POST_TAGS
---
_EOT_
}

md_body(){
        cat << _EOT_
${POST_BODY}

_EOT_
}

# ------------------------------------------------------

# POST_AUTHORが設定されていなければ読み込む
[ ! "${POST_AUTHOR}" ] && POST_AUTHOR=$(sed -n '/name="author"/{s|^.* content="\(.*\)">|\1|p}' "$PAGE")

# 日記の日付。時間はPOST_TIME固定
DIARY_DATE=$(${XMLLINT} 'string(//h2/span[@class="date"]/a)' "$PAGE" 2>/dev/null | sed -e 's|年|-|g; s|月|-|g; s|日||g; s|(.*)||g')
ANCHOR_DATE=$(${XMLLINT} 'string(//h2/span[@class="date"]/a/@href)' "$PAGE" 2>/dev/null | sed -e 's|^.*date=||; s|\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)|\1-\2-\3|')
# Last modified
DIARY_LASTMODIFIED=$(${XMLLINT} 'string(//span[@class="lm"])' "$PAGE" 2>/dev/null | sed 's|Update: ||g; s|更新||g; s|年|-|g; s|月|-|g; s|日||g')
DIARY_LASTMODIFIED_HEAD=$(sed -n '/http-equiv="Last-Modified"/{s|^.* content="\(.*\)">|\1|p}' "$PAGE")

# 日付フォーマット
DATE_FORMAT="%m/%d/%Y %r"
[ "${OUT_SWITCH}" = "markdown" ] && DATE_FORMAT="%F %T"

# 日記に日付があれば投稿はその日付。無くてLast modifiedがあればLast modifiedを日付に設定
# if [ "${DIARY_DATE}" ];then
if [[ $DIARY_DATE =~ ^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$ ]]; then
        POST_DATE=$(LANG=C date -d"${DIARY_DATE} ${POST_TIME}" +"${DATE_FORMAT}")
elif [[ $ANCHOR_DATE =~ ^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$ ]]; then
        POST_DATE=$(LANG=C date -d"${ANCHOR_DATE} ${POST_TIME}" +"${DATE_FORMAT}")
elif [ "${DIARY_LASTMODIFIED_HEAD}" ]; then
	POST_DATE=$(LANG=C date -d"${DIARY_LASTMODIFIED_HEAD}" +"${DATE_FORMAT}")
else
	POST_DATE=$(LANG=C date -d"${DIARY_LASTMODIFIED}" +"${DATE_FORMAT}")
fi

# 日記のSECTION数とCOMMENT数
readonly DIARY_SECTION_COUNT=$(grep 'class="section"' "$PAGE" | wc -l)
readonly DIARY_COMMENT_COUNT=$(grep 'span class="commentator"' "$PAGE" | wc -l)

# ------------------------------------------------------

#
# diary_comment [FILE] 
# コメントを出力。TrackBackがあればトラックバックとして読み込みます
#

diary_comment(){
	[ -z "${DIARY_COMMENT_COUNT}" ] && return

	local _i
	local _date

	for _i in $(seq 1 $DIARY_COMMENT_COUNT); do

		COMMENT_AUTHOR=$(${XMLLINT} "string(//div[@class=\"commentator\"][$_i]/span[@class=\"commentator\"])" "$1" 2>/dev/null) 
		# _date=$(${XMLLINT} "string(//div[@class=\"commentator\"][$_i]/span[@class=\"commenttime\"])" "$1" 2>/dev/null | sed 's|(\(.*\))|\1|g; s|(.)||g')
		_date=$(${XMLLINT} "string(//div[@class=\"commentator\"][$_i]/span[@class=\"commenttime\"])" "$1" 2>/dev/null | sed 's|年|-|g; s|月|-|g; s|日||g; s|(.)||g')
		COMMENT_DATE=$(LANG=C date -d "$_date" +"%m/%d/%Y %r")

		if [ "${COMMENT_AUTHOR}" = "TrackBack" ]; then
			COMMENT_URL=$(${XMLLINT} "//div[@class=\"commentbody\"]/p[$_i]/a" "$1" 2>/dev/null )
			COMMENT_TITLE=$(${XMLLINT} "//div[@class=\"commentbody\"]/p[$_i]" "$1" 2>/dev/null | sed '1d; $d; s|^\t*||g; s|<a .*<br>\(.*\)<br>.*|\1|')
			COMMENT_BODY=$(${XMLLINT} "//div[@class=\"commentbody\"]/p[$_i]" "$1" 2>/dev/null | sed '1d; $d; s|^\t*||g; s|<a .*<br>.*<br>\(.*\)|\1|')
			pingback
		else
			COMMENT_BODY=$(${XMLLINT} "string(//div[@class=\"commentbody\"]/p[$_i])" "$1" 2>/dev/null | sed '1d; $d; s|^\t*||g; s|<br>|\n|g')
			comment
		fi

	done
}

# ------------------------------------------------------

# SECTION内の不要タグ削除
CMD_CLEAN_POST='
/<a name="p[0-9]/{:loop N; /<\/a>/!b loop; s|<a name="p[0-9].*</span></a> ||g};
s|<a name="p[0-9].*</a> ||g;
s|<div class="tags">.*</div>||g;
s|<div class="socialbuttons">.*</div>||g;
s|<div class="sequel">.*</div>||g;
s|</div><div class="section">||g;
s|<p>||g;
s|</p>||g;'

# SECTION内のIMGパスを置換
CMD_REPLACE_IMG_PATH="
s|\(class=\"photo\" src=\"\)\(${DIARY_IMAGE_PATH}\)\(.*\" alt\)|\1${POST_IMAGE_PATH}\3|g;
s|\(<a href=\"\)\(${DIARY_IMAGE_PATH}\)\(.*\"\)|\1${POST_IMAGE_PATH}\3|g;
s|\( src=\"\)\(${DIARY_IMAGE_PATH}\)\(.*\"\)|\1${POST_IMAGE_PATH}\3|g;"

#
# day_post [FILE]
# 日記1日を投稿として出力
#

day_post(){
	local _i

	# 日記タイトルを投稿タイトルに
	POST_TITLE=$(${XMLLINT} "string(//h2/span[@class=\"title\"])" "$1" 2>/dev/null | tr -d '\n' | sed 's|^ *||; s| *$||')
	[ ! "${POST_TITLE}" ] && POST_TITLE=$(date -d $(${XMLLINT} 'string(//h2/span[@class="date"]/a)' "$1" 2>/dev/null) +"%Y%m%d")

	# タイトルとカテゴリーを分離
	ORG_POST_TITLE=${POST_TITLE}
	POST_TITLE=$(echo ${ORG_POST_TITLE} | sed -e 's/ *\[.*\] *//')
	CAT_STR=$(echo ${ORG_POST_TITLE} | sed -e 's/^ *\(\[.*\]\) *.*$/\1/')
	IFS_BAK="$IFS"
	IFS=,
	CATEGORY_ARR=($(echo ${CAT_STR} | sed -e 's/\]\[/,/g; s/\[\|\]//g'))
	IFS="${IFS_BAK}"

	# 日記1日分のタグ
	POST_TAGS=$(for _i in $(${XMLLINT} '//div[@class="tags"]' "$1" 2>/dev/null | sed 's|<[^>]*>||g; s|Tags: ||g'); do echo ${_i}; done | sort | uniq | paste -s -d",")

	# sectionの出力
	POST_BODY=$(${XMLLINT} "//div[@class=\"section\"]" "$1" 2>/dev/null | sed '1,2d; $d' | sed -e "${CMD_CLEAN_POST}" -e "${CMD_REPLACE_IMG_PATH}" )

	metadata
	body
	diary_comment $1
	echo "--------"

}

#
# markdown_post [FILE]
# 日記1日をMarkdownファイルとして出力
#

markdown_post(){
	local _i

	# 日記タイトルを投稿タイトルに
	POST_TITLE=$(${XMLLINT} "string(//h2/span[@class=\"title\"])" "$1" 2>/dev/null | tr -d '\n' | sed 's|^ *||; s| *$||')
	[ ! "${POST_TITLE}" ] && POST_TITLE=$(date -d $(${XMLLINT} 'string(//h2/span[@class="date"]/a)' "$1" 2>/dev/null) +"%Y%m%d")

	# タイトルとカテゴリーを分離
	ORG_POST_TITLE=${POST_TITLE}
	POST_TITLE=$(echo ${ORG_POST_TITLE} | sed -e 's/ *\[.*\] *//')
	CAT_STR=$(echo ${ORG_POST_TITLE} | sed -e 's/^ *\(\[.*\]\) *.*$/\1/')
	IFS_BAK="$IFS"
	IFS=,
	CATEGORY_ARR=($(echo ${CAT_STR} | sed -e 's/\]\[/,/g; s/\[\|\]//g'))
	IFS="${IFS_BAK}"

	# 日記1日分のタグ
	POST_TAGS=$(for _i in $(${XMLLINT} '//div[@class="tags"]' "$1" 2>/dev/null | sed 's|<[^>]*>||g; s|Tags: ||g'); do echo "- ${_i}"; done | sort | uniq )

	# sectionの出力
	POST_BODY=$(${XMLLINT} "//div[@class=\"section\"]" "$1" 2>/dev/null | sed '1,2d; $d' | sed -e "${CMD_CLEAN_POST}" -e "${CMD_REPLACE_IMG_PATH}" | ${PANDOC} - )

	md_frontmatter
	md_body

}

#
# section_post [FILE] 
# 日記セクションを投稿として出力
#

section_post(){

	local _section
	local _title_clean_cmd='s|<h3>\(.*\)</h3>|\1|g; s|<a name="p[0-9].*</a> ||g'

	local _i=1
	while [ $_i -le $DIARY_SECTION_COUNT ]; do
                POST_TITLE=$(${XMLLINT} "//div[@class=\"section\"][$_i]/h3" "$1" 2>/dev/null | tr -d '\n' | sed -e "$_title_clean_cmd")
		# タイトルとカテゴリーを分離
	        ORG_POST_TITLE=${POST_TITLE}
                POST_TITLE=$(echo ${ORG_POST_TITLE} | sed -e 's/ *\[.*\] *//')
		CAT_STR=$(echo ${ORG_POST_TITLE} | sed -e 's/^ *\(\[.*\]\) *.*$/\1/')
		IFS_BAK="$IFS"
		IFS=,
		CATEGORY_ARR=($(echo ${CAT_STR} | sed -e 's/\]\[/,/g; s/\[\|\]//g'))
		IFS="${IFS_BAK}"

		POST_TAGS=$(${XMLLINT} "string(//div[@class=\"section\"][$_i]/div[@class=\"tags\"])" "$1" 2>/dev/null | sed 's|Tags: \(.*\) |\1|g;s| |,|g')
		POST_BODY=$(${XMLLINT} "//div[@class=\"section\"][$_i]" "$1" 2>/dev/null \
		| sed '1,2d; $d' | sed -e '/<h3>/{:loop N; /<\/h3>/!b loop; s|<h3>.*</h3>||g}' -e "${CMD_CLEAN_POST}" -e "${CMD_REPLACE_IMG_PATH}")

		while [ -z "$(${XMLLINT} "string(//div[@class=\"section\"][$(( $_i + 1 ))]/h3)" "$1" 2>/dev/null)" ] && [ $_i -le $DIARY_SECTION_COUNT ]; do
			_i=$(( $_i + 1 ))
			_section=$(${XMLLINT} "//div[@class=\"section\"][$_i]" "$1" 2>/dev/null \
			| sed '1,2d; $d' | sed -e '/<h3>/{:loop N; /<\/h3>/!b loop; s|<h3>.*</h3>||g}' -e "${CMD_CLEAN_POST}" -e "${CMD_REPLACE_IMG_PATH}")
			POST_BODY="$POST_BODY

$_section"
		done

		_i=$(( $_i + 1 ))

		metadata
		body	
		[ $_i -gt $DIARY_SECTION_COUNT ] && diary_comment $1
		echo "--------"

	done

}


# ------------------------------------------------------

if [ "${OUT_SWITCH}" = "markdown" ]; then
    markdown_post $PAGE
elif [ "${OUT_SWITCH}" = "section" ]; then
    section_post $PAGE
else
    day_post $PAGE
fi
