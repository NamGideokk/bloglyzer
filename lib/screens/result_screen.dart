import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/blog_analysis.dart';
import '../services/seo_scorer.dart';
import 'image_gallery_screen.dart';

class ResultScreen extends StatefulWidget {
  final BlogAnalysis analysis;
  final String url;

  const ResultScreen({super.key, required this.analysis, required this.url});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _keywordController = TextEditingController();
  final _scrollController = ScrollController();
  final _keywordSectionKey = GlobalKey();
  final _inputBarKey = GlobalKey();
  final _scorer = SeoScorer();
  final _keywords = <String>[];
  late SeoResult _seoResult;
  double _inputBarHeight = 0;

  @override
  void initState() {
    super.initState();
    _recalculate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInputBar());
  }

  void _measureInputBar() {
    final context = _inputBarKey.currentContext;
    if (context != null) {
      final height = context.size?.height ?? 0;
      if (height != _inputBarHeight) {
        setState(() => _inputBarHeight = height);
      }
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _recalculate() {
    _seoResult = _scorer.evaluate(widget.analysis, _keywords);
  }

  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;
    if (_keywords.contains(keyword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 추가된 키워드입니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _keywords.add(keyword);
      _keywordController.clear();
      _recalculate();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keywordSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 300));
      }
    });
  }

  void _removeKeyword(int index) {
    setState(() {
      _keywords.removeAt(index);
      _recalculate();
    });
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

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, _inputBarHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL
            _buildSection(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse(widget.url),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        widget.url,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL이 복사되었습니다'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(Icons.copy, size: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 제목
            _buildSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 기본 분석 결과
            _buildSection(
              child: Column(
                children: [
                  _buildStatRow(
                      '전체 글자수', '${_formatNumber(analysis.totalCharCount)}자'),
                  const SizedBox(height: 16),
                  _buildStatRow('공백 제외 글자수',
                      '${_formatNumber(analysis.charCountNoSpaces)}자'),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: analysis.imageUrls.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageGalleryScreen(
                                  imageUrls: analysis.imageUrls,
                                  title: analysis.title,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '이미지 수',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (analysis.imageUrls.isNotEmpty)
                              Icon(Icons.chevron_right,
                                  size: 18, color: Colors.grey.shade400),
                          ],
                        ),
                        Text(
                          '${analysis.imageCount}장',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SEO 점수
            _buildSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SEO 점수',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _scoreColor(_seoResult.totalScore)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_seoResult.totalScore}점',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(_seoResult.totalScore),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _seoResult.totalScore / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: _scoreColor(_seoResult.totalScore),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildScoreDetail('글자수 점수', _seoResult.charScore, 30),
                  const SizedBox(height: 8),
                  _buildScoreDetail('이미지 점수', _seoResult.imageScore, 30),
                  const SizedBox(height: 8),
                  _buildScoreDetail(
                      '키워드 빈도',
                      _seoResult.keywordScores.isNotEmpty
                          ? _scoreKeywordFreq()
                          : 0,
                      25),
                  const SizedBox(height: 8),
                  _buildScoreDetail(
                      '제목 키워드',
                      _seoResult.keywordScores.isNotEmpty &&
                              _seoResult.keywordScores.first.inTitle
                          ? 15
                          : 0,
                      15),
                ],
              ),
            ),

            // 개선 코멘트
            if (_seoResult.comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '개선 포인트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._seoResult.comments.map((comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            // 키워드 분석 결과
            const SizedBox(height: 16),
            _buildSection(
              key: _keywordSectionKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '키워드 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_keywords.isEmpty)
                    Text(
                      '키워드를 추가해 주세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    )
                  else
                    ..._buildKeywordResults(),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

          // 하단 고정 키워드 입력란
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              key: _inputBarKey,
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordController,
                      decoration: InputDecoration(
                        hintText: '키워드 입력',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF03C75A), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addKeyword(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _addKeyword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('추가'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _scoreKeywordFreq() {
    if (_seoResult.keywordScores.isEmpty) return 0;
    final freq = _seoResult.keywordScores.first.frequency;
    int base;
    if (freq >= 8) {
      base = 25;
    } else if (freq >= 5) {
      base = 19;
    } else if (freq >= 3) {
      base = 13;
    } else if (freq >= 1) {
      base = 6;
    } else {
      base = 0;
    }
    // 서브 키워드 감점 반영
    for (int i = 1; i < _seoResult.keywordScores.length; i++) {
      base += _seoResult.keywordScores[i].score; // score is negative penalty
    }
    return base.clamp(0, 25);
  }

  List<Widget> _buildKeywordResults() {
    return List.generate(_seoResult.keywordScores.length, (index) {
      final ks = _seoResult.keywordScores[index];
      final isPrimary = index == 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF03C75A).withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF03C75A).withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ks.keyword,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03C75A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '메인',
                            style: TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '본문 ${ks.frequency}회  |  제목 ${ks.inTitle ? "O" : "X"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _removeKeyword(index),
              child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSection({Key? key, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDetail(String label, int score, int maxScore) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maxScore > 0 ? score / maxScore : 0,
              backgroundColor: Colors.grey.shade200,
              color: _scoreColor(
                  maxScore > 0 ? (score / maxScore * 100).round() : 0),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$score / $maxScore',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF03C75A);
    if (score >= 60) return Colors.amber.shade700;
    if (score >= 40) return Colors.orange;
    return Colors.red.shade600;
  }
}
