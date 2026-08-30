import 'package:flutter/material.dart';

/// 星による評価入力。
///
/// タップすると整数値が入り、そのまま横にドラッグすると 0.1 刻みで
/// 微調整できる（ADR-004）。店頭ではタップ 1 回で終わらせ、
/// じっくり付けたいときだけドラッグする、という使い分けを想定している。
class RatingStars extends StatelessWidget {
  const RatingStars({required this.rating, required this.onChanged, super.key});

  /// 1.0〜5.0。0 は「まだ付けていない」を表す。
  final double rating;

  final ValueChanged<double> onChanged;

  static const _starCount = 5;
  static const _starSize = 44.0;

  @override
  Widget build(BuildContext context) {
    const width = _starSize * _starCount;

    return GestureDetector(
      // タップは整数。指を置いた位置の星を丸ごと選ぶ。
      onTapDown: (details) =>
          onChanged(_wholeStarAt(details.localPosition.dx, width)),
      // ドラッグは 0.1 刻み。
      onHorizontalDragStart: (details) =>
          onChanged(_preciseAt(details.localPosition.dx, width)),
      onHorizontalDragUpdate: (details) =>
          onChanged(_preciseAt(details.localPosition.dx, width)),
      child: SizedBox(
        width: width,
        height: _starSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _starCount; i++)
              _Star(fill: (rating - i).clamp(0.0, 1.0)),
          ],
        ),
      ),
    );
  }

  /// タップ位置の星を、その星まで塗った整数値にする。
  double _wholeStarAt(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    return (ratio * _starCount).ceil().clamp(1, _starCount).toDouble();
  }

  /// ドラッグ位置を 0.1 刻みに丸める。下限は 1.0。
  double _preciseAt(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    final raw = ratio * _starCount;
    final rounded = (raw * 10).round() / 10;
    return rounded.clamp(1.0, _starCount.toDouble());
  }
}

/// 星 1 つ。[fill] は 0.0〜1.0 で、途中まで塗るために使う。
class _Star extends StatelessWidget {
  const _Star({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: RatingStars._starSize,
      height: RatingStars._starSize,
      child: Stack(
        children: [
          Icon(
            Icons.star,
            size: RatingStars._starSize,
            color: scheme.surfaceContainerHighest,
          ),
          // 塗る幅を変えて、0.1 刻みを見た目に出す。
          ClipRect(
            clipper: _FillClipper(fill),
            child: Icon(
              Icons.star,
              size: RatingStars._starSize,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FillClipper extends CustomClipper<Rect> {
  const _FillClipper(this.fill);

  final double fill;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_FillClipper oldClipper) => oldClipper.fill != fill;
}

/// 評価の数値表示。まだ付けていないときは何も出さない。
class RatingValue extends StatelessWidget {
  const RatingValue({required this.rating, super.key});

  final double rating;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) {
      return Text(
        '星をタップして評価',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Text(
      rating.toStringAsFixed(1),
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontFeatures: const []),
    );
  }
}

/// 読み取り専用の星。一覧やカードで評価を出すために使う。
///
/// 入力用の [RatingStars] とは別にする。あちらは指の位置を計算するために
/// 固定幅が要るが、こちらは行に収まる大きさで並べたいだけ。
class RatingStarsDisplay extends StatelessWidget {
  const RatingStarsDisplay({required this.rating, this.size = 16, super.key});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Icon(
                  Icons.star,
                  size: size,
                  color: scheme.surfaceContainerHighest,
                ),
                ClipRect(
                  clipper: _FillClipper((rating - i).clamp(0.0, 1.0)),
                  child: Icon(Icons.star, size: size, color: scheme.primary),
                ),
              ],
            ),
          ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
