#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re
import datetime
import logging
import urllib.parse
import xml.etree.ElementTree as ET

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

img_src_table = [
    ['../image/', './wp-content/image/'],
    ['../photo/', './wp-content/photo/']
]

a_href_table = [
    ['../', './archives/']
]

old_base_url = 'http://www.yoshimura-s.jp/blog'
new_base_url = 'https://www.yoshimura-s.jp'

max_quoted_title_length = 200


def gen_date_title_dict(data):

    contents = data.split('--------\n')
    date_title_dict = {}
    for content in contents:
        lines = content.split('\n')
        for line in lines:
            if re.match(r'^-----$', line):
                break
            m1 = re.match(r'TITLE: (.+)$', line)
            m2 = re.match(r'DATE: (.+)$', line)
            if m1:
                title = m1.group(1)
            if m2:
                date_str = m2.group(1)
                
        # date_obj = datetime.datetime.strptime(date_str, '%m/%d/%Y %I:%M:%S %p')
        date_obj = datetime.datetime.strptime(date_str.split(' ')[0], '%m/%d/%Y')
        date_key = date_obj.strftime('%Y%m%d')
        date_title_dict[date_key] = title
        logger.debug('{} - {}'.format(date_key, title))

    return date_title_dict


def quote_string(string, max_length):

    quoted_string = ''
    for char in string:
        quoted_char = urllib.parse.quote(char)
        if len(quoted_string) + len(quoted_char) > max_length:
            break
        else:
            quoted_string += quoted_char
    return quoted_string


def sanitize_title(title):
    """ WordPress の wp-include/formatting.php の sanitize_title_with_dashes(), 
    sanitize_file_name() を参考に
    """
    special_chars = ['?', '[', ']', '/', '\\', '=', '<', '>', ':', ';', ',', "'", '"', '&', '$', '#', '*', '(', ')', '|', '~', '`', '!', '{', '}', '%', '+']
    for c in special_chars:
        title = title.replace(c, '')
    
    # Remove percent signs that are not part of an octet.
    title = title.replace('%', '')

    # Convert space and '+' to '-'
    title = title.replace(' ', '-')
    title = title.replace('+', '-')

    title = title.lower()
    title = quote_string(title, max_quoted_title_length)
    title = title.lower()

    # Convert &nbsp, &ndash, and &mdash to hyphens.
    title = re.sub(r'%c2%a0|%e2%80%93|%e2%80%94', '-', title )
    # Convert &nbsp, &ndash, and &mdash HTML entities to hyphens.
    title = re.sub(r'&nbsp;|&#160;|&ndash;|&#8211;|&mdash;|&#8212;', '-', title )
    # Convert forward slash to hyphen.
    title = title.replace('/', '-')

    # Strip these characters entirely.
    remove_chars = [
        # Soft hyphens.
        '%c2%ad',
        # &iexcl and &iquest.
        '%c2%a1',
        '%c2%bf',
        # Angle quotes.
        '%c2%ab',
        '%c2%bb',
        '%e2%80%b9',
        '%e2%80%ba',
        # Curly quotes.
        '%e2%80%98',
        '%e2%80%99',
        '%e2%80%9c',
        '%e2%80%9d',
        '%e2%80%9a',
        '%e2%80%9b',
        '%e2%80%9e',
        '%e2%80%9f',
        # &copy, &reg, &deg, &hellip, and &trade.
        '%c2%a9',
        '%c2%ae',
        '%c2%b0',
        '%e2%80%a6',
        '%e2%84%a2',
        # Acute accents.
        '%c2%b4',
        '%cb%8a',
        '%cc%81',
        '%cd%81',
        # Grave accent, macron, caron.
        '%cc%80',
        '%cc%84',
        '%cc%8c'
    ]
        
    for c in remove_chars:
        title = title.replace(c, '')
        
    # Convert &times to 'x'.
    title = title.replace('%c3%97', 'x')

    # Kill entities.
    title = re.sub(r'&.+?;', '', title )
    title = title.replace('.', '-')

    title = re.sub('[^%a-z0-9 _-]', '', title)
    title = re.sub('\s+', '-', title)
    title = re.sub('-+', '-', title)
    title = re.sub('^\-', '', title)
    title = re.sub('\-$', '', title)

    return title


def gen_new_url(url, date_title_dict):

    m = re.search(r'\?date=(\d{8})', url)
    try:
        url_date = m.group(1)
        title = date_title_dict[url_date]
        logger.debug('{} - {}'.format(url_date, title))
    except AttributeError:
        logger.info('url {} does not contain date option'.format(url))
        return None
    except KeyError:
        logger.info('could not find corresponding title for {}'.format(url_date))
        return None
    m = re.match(r'^(\d{4})(\d{2})(\d{2})$', url_date)
    try:
        year = m.group(1)
        month = m.group(2)
        day = m.group(3)
    except AttributeError:
        logger.info('invalid date option {}'.format(url))
        return None
    sanitized_title = sanitize_title(title)
    new_url = '/'.join([new_base_url, year, month, sanitized_title]) + '/'
    return new_url
        

def rewrite_link(data):

    date_title_dict = gen_date_title_dict(data)

    match_list = re.findall('href="' + old_base_url + r'/\?date=\d{8}"', data)
    match_list += re.findall('href="' + r'\?date=\d{8}"', data)
    match_list = sorted(list(set(match_list)))
    for match_href in match_list:
        logger.debug('match href: {}'.format(match_href))
        match_url = match_href.replace('href="', '').replace('"', '')
        new_url = gen_new_url(match_url, date_title_dict)
        if new_url is None:
            logger.info('new url not found for {}'.format(match_url))
            continue
        new_href = 'href="{}"'.format(new_url)
        logger.debug('replacing {} to {}'.format(match_href, new_href))
        data = new_href.join(data.split(match_href))

    for img_src in img_src_table:
        org = r'src="' + img_src[0]
        dst = r'src="' + img_src[1]
        logger.debug('{} -> {}'.format(org, dst))
        data = data.replace(org, dst)

    for a_href in a_href_table:
        org = r'href="' + a_href[0]
        dst = r'href="' + a_href[1]
        logger.debug('{} -> {}'.format(org, dst))
        data = data.replace(org, dst)

    return data


def rewrite_youtube_embedding(data):

    ptn = re.compile(r' *<iframe .*?</iframe>|<object .*?</object>', re.DOTALL)
    match_list = re.findall(ptn, data)
    for iframe_str in match_list:
        logger.debug(iframe_str)
        m = re.search(r'//www.youtube.com/(embed|v)/([A-Za-z0-9\-_]*?)(&amp;.*)?"', iframe_str)
        if not m:
            continue
        id = m.group(2)
        logger.debug(id)
        new_elem = ('\n<figure class="wp-block-embed-youtube wp-block-embed is-type-video is-provider-youtube wp-embed-aspect-16-9 wp-has-aspect-ratio"><div class="wp-block-embed__wrapper">\n' +
                    '<iframe width="750" height="422" src="https://www.youtube.com/embed/{}?feature=oembed" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>\n'.format(id) + '</div></figure>\n')
        data = new_elem.join(data.split(iframe_str))
        
    return data


if __name__ == '__main__':

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file, 'r') as f:
        input_data = f.read()

    output_data = rewrite_link(input_data)
    output_data = rewrite_youtube_embedding(output_data)

    with open(output_file, 'w') as f:
        f.write(output_data)
