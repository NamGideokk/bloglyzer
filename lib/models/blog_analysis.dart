class BlogAnalysis {
  final String title;
  final String bodyText;
  final int totalCharCount;
  final int charCountNoSpaces;
  final List<String> imageUrls;
  int get imageCount => imageUrls.length;

  BlogAnalysis({
    required this.title,
    required this.bodyText,
    required this.totalCharCount,
    required this.charCountNoSpaces,
    required this.imageUrls,
  });
}

class KeywordScore {
  final String keyword;
  final int frequency;
  final bool inTitle;
  final int score;
  final String? comment;

  KeywordScore({
    required this.keyword,
    required this.frequency,
    required this.inTitle,
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
