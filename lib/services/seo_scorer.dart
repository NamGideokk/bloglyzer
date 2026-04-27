import '../models/blog_analysis.dart';

class SeoScorer {
  SeoResult evaluate(BlogAnalysis analysis, List<String> keywords) {
    final charScore = _scoreCharCount(analysis.totalCharCount);
    final imageScore = _scoreImageCount(analysis.imageCount);
    final comments = <String>[];

    comments.addAll(_charComments(analysis.totalCharCount));
    comments.addAll(_imageComments(analysis.imageCount));

    final keywordScores = <KeywordScore>[];

    if (keywords.isEmpty) {
      // 키워드 없을 때: 50점 만점을 100점 스케일로 환산
      final baseScore = charScore + imageScore;
      final totalScore = (baseScore / 50 * 100).round();

      return SeoResult(
        charScore: charScore,
        imageScore: imageScore,
        keywordScores: [],
        totalScore: totalScore,
        comments: comments,
      );
    }

    // 첫 번째 키워드(메인 키워드) 기준으로 점수 계산
    final primaryKeyword = keywords.first;
    final primaryFrequency = _countKeyword(analysis.bodyText, primaryKeyword);
    final primaryInTitle = analysis.title.contains(primaryKeyword);
    final primaryInFirstPara =
        analysis.firstParagraph.contains(primaryKeyword);

    final freqScore = _scoreKeywordFrequency(primaryFrequency);
    final titleScore = primaryInTitle ? 15 : 0;
    final firstParaScore = primaryInFirstPara ? 15 : 0;
    final primaryScore = freqScore + titleScore + firstParaScore;

    comments.addAll(
        _keywordComments(primaryKeyword, primaryFrequency, primaryInTitle,
            primaryInFirstPara));

    keywordScores.add(KeywordScore(
      keyword: primaryKeyword,
      frequency: primaryFrequency,
      inTitle: primaryInTitle,
      inFirstParagraph: primaryInFirstPara,
      score: primaryScore,
    ));

    // 나머지 키워드는 빈도 정보만 표시
    for (int i = 1; i < keywords.length; i++) {
      final keyword = keywords[i];
      final frequency = _countKeyword(analysis.bodyText, keyword);
      keywordScores.add(KeywordScore(
        keyword: keyword,
        frequency: frequency,
        inTitle: analysis.title.contains(keyword),
        inFirstParagraph: analysis.firstParagraph.contains(keyword),
        score: 0,
      ));
    }

    final totalScore =
        charScore + imageScore + freqScore + titleScore + firstParaScore;

    return SeoResult(
      charScore: charScore,
      imageScore: imageScore,
      keywordScores: keywordScores,
      totalScore: totalScore,
      comments: comments,
    );
  }

  int _countKeyword(String text, String keyword) {
    final escaped = RegExp.escape(keyword);
    return RegExp(escaped, caseSensitive: false).allMatches(text).length;
  }

  int _scoreCharCount(int count) {
    if (count >= 2500) return 25;
    if (count >= 1500) return 20;
    if (count >= 1000) return 15;
    if (count >= 500) return 10;
    return 5;
  }

  int _scoreImageCount(int count) {
    if (count >= 15) return 25;
    if (count >= 10) return 20;
    if (count >= 5) return 15;
    if (count >= 1) return 10;
    return 0;
  }

  int _scoreKeywordFrequency(int count) {
    if (count >= 8) return 20;
    if (count >= 5) return 15;
    if (count >= 3) return 10;
    if (count >= 1) return 5;
    return 0;
  }

  List<String> _charComments(int count) {
    if (count >= 2500) return [];
    final formatted = _formatNumber(count);
    if (count >= 1500) {
      return ['본문 글자 수가 $formatted자로 양호합니다. 2,500자 이상이면 더 좋습니다.'];
    }
    if (count >= 500) {
      return ['본문 글자 수가 $formatted자입니다. 1,500자 이상이면 SEO에 유리합니다.'];
    }
    return [
      '본문 글자 수가 $formatted자로 매우 부족합니다. 최소 1,500자 이상 작성을 권장합니다.'
    ];
  }

  List<String> _imageComments(int count) {
    if (count >= 15) return [];
    if (count >= 10) {
      return ['이미지가 $count장으로 양호합니다. 15장 이상이면 더 좋습니다.'];
    }
    if (count >= 1) {
      return ['이미지가 $count장입니다. 10장 이상 사용하면 SEO 점수가 올라갑니다.'];
    }
    return ['이미지가 하나도 없습니다. 최소 10장 이상의 관련 이미지를 추가하세요.'];
  }

  List<String> _keywordComments(
      String keyword, int frequency, bool inTitle, bool inFirstPara) {
    final comments = <String>[];

    if (frequency == 0) {
      comments.add("메인 키워드 '$keyword'이(가) 본문에 포함되어 있지 않습니다. 최소 5회 이상 자연스럽게 추가하세요.");
    } else if (frequency < 5) {
      comments.add(
          "메인 키워드 '$keyword'이(가) $frequency회 사용되었습니다. 최소 5회 이상 자연스럽게 추가하는 것을 추천합니다.");
    } else if (frequency < 8) {
      comments.add(
          "메인 키워드 '$keyword'이(가) $frequency회 사용되었습니다. 8회 이상이면 더 좋습니다.");
    }

    if (!inTitle) {
      comments.add(
          "메인 키워드 '$keyword'이(가) 제목에 포함되어 있지 않습니다. 제목에 키워드를 넣으면 검색 노출에 유리합니다.");
    }

    if (!inFirstPara) {
      comments.add(
          "메인 키워드 '$keyword'이(가) 첫 문단에 포함되어 있지 않습니다. 도입부에 키워드를 배치하면 SEO에 효과적입니다.");
    }

    return comments;
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
