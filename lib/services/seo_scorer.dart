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
      final baseScore = charScore + imageScore;
      final totalScore = (baseScore / 60 * 100).round();

      return SeoResult(
        charScore: charScore,
        imageScore: imageScore,
        keywordScores: [],
        totalScore: totalScore,
        comments: comments,
      );
    }

    final primaryKeyword = keywords.first;
    final primaryFrequency = _countKeyword(analysis.bodyText, primaryKeyword);
    final primaryInTitle = analysis.title.contains(primaryKeyword);

    final freqScore = _scoreKeywordFrequency(primaryFrequency);
    final titleScore = primaryInTitle ? 15 : 0;
    final primaryScore = freqScore + titleScore;

    comments.addAll(
        _keywordComments(primaryKeyword, primaryFrequency, primaryInTitle));

    keywordScores.add(KeywordScore(
      keyword: primaryKeyword,
      frequency: primaryFrequency,
      inTitle: primaryInTitle,
      score: primaryScore,
    ));

    int subPenalty = 0;
    for (int i = 1; i < keywords.length; i++) {
      final keyword = keywords[i];
      final frequency = _countKeyword(analysis.bodyText, keyword);
      final penalty = _subKeywordPenalty(frequency);
      subPenalty += penalty;
      keywordScores.add(KeywordScore(
        keyword: keyword,
        frequency: frequency,
        inTitle: analysis.title.contains(keyword),
        score: -penalty,
      ));
      if (penalty > 0) {
        comments.add(
            "서브 키워드 '$keyword'이(가) ${frequency == 0 ? '본문에 포함되어 있지 않습니다' : '$frequency회만 사용되었습니다'}. 5회 이상 자연스럽게 추가하세요.");
      }
    }

    final adjustedFreqScore = (freqScore - subPenalty).clamp(0, 25);
    final totalScore = charScore + imageScore + adjustedFreqScore + titleScore;

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
    if (count >= 2500) return 30;
    if (count >= 1500) return 24;
    if (count >= 1000) return 18;
    if (count >= 500) return 12;
    return 6;
  }

  int _scoreImageCount(int count) {
    if (count >= 15) return 30;
    if (count >= 10) return 24;
    if (count >= 5) return 18;
    if (count >= 1) return 12;
    return 0;
  }

  int _subKeywordPenalty(int frequency) {
    if (frequency >= 5) return 0;
    if (frequency >= 3) return 1;
    if (frequency >= 1) return 2;
    return 3;
  }

  int _scoreKeywordFrequency(int count) {
    if (count >= 8) return 25;
    if (count >= 5) return 19;
    if (count >= 3) return 13;
    if (count >= 1) return 6;
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
      String keyword, int frequency, bool inTitle) {
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
