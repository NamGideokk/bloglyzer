import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/blog_analysis.dart';
import '../services/seo_scorer.dart';

class ResultScreen extends StatefulWidget {
  final BlogAnalysis analysis;
  final String url;

  const ResultScreen({super.key, required this.analysis, required this.url});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _keywordController = TextEditingController();
  final _scorer = SeoScorer();
  final _keywords = <String>[];
  late SeoResult _seoResult;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _keywordController.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL
            _buildSection(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.url,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  const Divider(height: 24),
                  _buildStatRow('공백 제외 글자수',
                      '${_formatNumber(analysis.charCountNoSpaces)}자'),
                  const Divider(height: 24),
                  _buildStatRow('이미지 수', '${analysis.imageCount}장'),
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
                  const SizedBox(height: 16),
                  _buildScoreDetail('글자수 점수', _seoResult.charScore, 25),
                  const SizedBox(height: 8),
                  _buildScoreDetail('이미지 점수', _seoResult.imageScore, 25),
                  if (_keywords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildScoreDetail(
                        '키워드 빈도',
                        _seoResult.keywordScores.isNotEmpty
                            ? _scoreKeywordFreq()
                            : 0,
                        20),
                    const SizedBox(height: 8),
                    _buildScoreDetail(
                        '제목 키워드',
                        _seoResult.keywordScores.isNotEmpty &&
                                _seoResult.keywordScores.first.inTitle
                            ? 15
                            : 0,
                        15),
                    const SizedBox(height: 8),
                    _buildScoreDetail(
                        '첫 문단 키워드',
                        _seoResult.keywordScores.isNotEmpty &&
                                _seoResult.keywordScores.first.inFirstParagraph
                            ? 15
                            : 0,
                        15),
                  ],
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

            const SizedBox(height: 16),

            // 키워드 입력
            _buildSection(
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
                  Row(
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
                  if (_keywords.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._buildKeywordResults(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  int _scoreKeywordFreq() {
    if (_seoResult.keywordScores.isEmpty) return 0;
    final freq = _seoResult.keywordScores.first.frequency;
    if (freq >= 8) return 20;
    if (freq >= 5) return 15;
    if (freq >= 3) return 10;
    if (freq >= 1) return 5;
    return 0;
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
                    '본문 ${ks.frequency}회  |  제목 ${ks.inTitle ? "O" : "X"}  |  첫문단 ${ks.inFirstParagraph ? "O" : "X"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              onPressed: () => _removeKeyword(index),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
