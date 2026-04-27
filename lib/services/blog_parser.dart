import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/blog_analysis.dart';

class BlogParseException implements Exception {
  final String message;
  BlogParseException(this.message);

  @override
  String toString() => message;
}

class BlogParser {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  Future<BlogAnalysis> analyzeBlogUrl(String url) async {
    final parsed = _parseUrl(url.trim());
    final html = await _fetchHtml(parsed.blogId, parsed.logNo);
    return _extractContent(html);
  }

  ({String blogId, String logNo}) _parseUrl(String url) {
    if (url.isEmpty) {
      throw BlogParseException('URL을 입력해주세요');
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw BlogParseException('올바른 네이버 블로그 URL이 아닙니다');
    }

    final host = uri.host;
    if (host != 'blog.naver.com' && host != 'm.blog.naver.com') {
      throw BlogParseException('네이버 블로그 URL만 지원합니다');
    }

    String? blogId;
    String? logNo;

    if (uri.path.contains('PostView.naver') ||
        uri.path.contains('PostView.nhn')) {
      blogId = uri.queryParameters['blogId'];
      logNo = uri.queryParameters['logNo'];
    } else {
      final segments =
          uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        blogId = segments[0];
        logNo = segments[1];
      }
    }

    if (blogId == null ||
        blogId.isEmpty ||
        logNo == null ||
        logNo.isEmpty) {
      throw BlogParseException('올바른 네이버 블로그 URL이 아닙니다');
    }

    if (int.tryParse(logNo) == null) {
      throw BlogParseException('올바른 네이버 블로그 URL이 아닙니다');
    }

    return (blogId: blogId, logNo: logNo);
  }

  Future<String> _fetchHtml(String blogId, String logNo) async {
    final url = Uri.parse(
      'https://blog.naver.com/PostView.naver'
      '?blogId=$blogId&logNo=$logNo'
      '&redirect=Dlog&widgetTypeCall=true&directAccess=true',
    );

    final http.Response response;
    try {
      response = await http
          .get(url, headers: {
            'User-Agent': _userAgent,
            'Referer': 'https://blog.naver.com/$blogId/$logNo',
          })
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw BlogParseException('서버 응답 시간이 초과되었습니다. 다시 시도해주세요');
    } on SocketException {
      throw BlogParseException('네트워크 연결을 확인해주세요');
    }

    if (response.statusCode == 404) {
      throw BlogParseException('존재하지 않는 포스트입니다');
    }

    if (response.statusCode != 200) {
      throw BlogParseException('서버 오류가 발생했습니다 (${response.statusCode})');
    }

    final body = response.body;

    if (body.contains('이 글은 작성자만 볼 수 있습니다') ||
        body.contains('본문 기능 제한') ||
        body.contains('비공개') ||
        body.contains('서로이웃까지만 공개')) {
      throw BlogParseException('비공개 포스트이거나 접근할 수 없습니다');
    }

    return body;
  }

  BlogAnalysis _extractContent(String html) {
    final document = html_parser.parse(html);

    final title = _extractTitle(document);
    final bodyText = _extractBodyText(document);
    final imageCount = _countImages(document);

    if (bodyText.isEmpty) {
      throw BlogParseException('포스트 내용을 파싱할 수 없습니다. 지원하지 않는 형식일 수 있습니다');
    }

    return BlogAnalysis(
      title: title,
      bodyText: bodyText,
      totalCharCount: bodyText.length,
      charCountNoSpaces: bodyText.replaceAll(RegExp(r'\s'), '').length,
      imageCount: imageCount,
    );
  }

  String _extractTitle(Document document) {
    // SmartEditor ONE
    final seTitle = document.querySelector('.se-title-text');
    if (seTitle != null && seTitle.text.trim().isNotEmpty) {
      return seTitle.text.trim();
    }

    // Old editor
    final oldTitle = document.querySelector('.htitle');
    if (oldTitle != null && oldTitle.text.trim().isNotEmpty) {
      return oldTitle.text.trim();
    }

    // Fallback: <title> tag
    final titleTag = document.querySelector('title');
    if (titleTag != null) {
      return titleTag.text
          .replaceAll(' : 네이버 블로그', '')
          .trim();
    }

    return '제목 없음';
  }

  String _extractBodyText(Document document) {
    // SmartEditor ONE
    final seContainer = document.querySelector('.se-main-container');
    if (seContainer != null) {
      final paragraphs = seContainer.querySelectorAll('.se-text-paragraph');
      if (paragraphs.isNotEmpty) {
        return paragraphs.map((p) => p.text.trim()).join('\n');
      }
      // fallback: get all text from container
      return seContainer.text.trim();
    }

    // Old editor
    final oldContainer = document.querySelector('#postViewArea');
    if (oldContainer != null) {
      return oldContainer.text.trim();
    }

    return '';
  }

  int _countImages(Document document) {
    // SmartEditor ONE: count .se-image-resource (actual content images)
    final seContainer = document.querySelector('.se-main-container');
    if (seContainer != null) {
      final images = seContainer.querySelectorAll('.se-image-resource');
      if (images.isNotEmpty) return images.length;

      // fallback: count img tags inside se-module-image
      final moduleImages =
          seContainer.querySelectorAll('.se-module-image img');
      if (moduleImages.isNotEmpty) return moduleImages.length;

      // last fallback: count all img in container, excluding stickers
      final allImgs = seContainer.querySelectorAll('img');
      return allImgs
          .where((img) {
            final className = img.attributes['class'] ?? '';
            final src = img.attributes['src'] ?? '';
            return !className.contains('sticker') &&
                !src.contains('storep-phinf.pstatic.net/ogq_');
          })
          .length;
    }

    // Old editor
    final oldContainer = document.querySelector('#postViewArea');
    if (oldContainer != null) {
      final imgs = oldContainer.querySelectorAll('img');
      return imgs
          .where((img) {
            final className = img.attributes['class'] ?? '';
            return !className.contains('emoticon') &&
                !className.contains('sticker');
          })
          .length;
    }

    return 0;
  }
}
