class BlogAnalysis {
  final String title;
  final String bodyText;
  final String firstParagraph;
  final int totalCharCount;
  final int charCountNoSpaces;
  final int imageCount;

  BlogAnalysis({
    required this.title,
    required this.bodyText,
    required this.firstParagraph,
    required this.totalCharCount,
    required this.charCountNoSpaces,
    required this.imageCount,
  });
}

class KeywordScore {
  final String keyword;
  final int frequency;
  final bool inTitle;
  final bool inFirstParagraph;
  final int score;
  final String? comment;

  KeywordScore({
    required this.keyword,
    required this.frequency,
    required this.inTitle,
    required this.inFirstParagraph,
    required this.score,
    this.comment,
  });
}

class SeoResult {
  final int charScore;
  final int imageScore;
  final List<KeywordScore> keywordScores;
  final int totalScore;
  final List<String> comments;

  SeoResult({
    required this.charScore,
    required this.imageScore,
    required this.keywordScores,
    required this.totalScore,
    required this.comments,
  });
}
