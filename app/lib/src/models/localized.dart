/// ロケールに応じた名前の解決。
///
/// v1 の UI は日本語のみだが、データは name_ja / name_en の 2 カラムを持つ。
/// 3 言語目が必要になったときの移行をデータ層に閉じるため、
/// **name_ja を直接参照せず必ずこの関数を経由する**
/// （docs/data-model.md 8）。
String localizedName({
  required String nameEn,
  String? nameJa,
  String locale = 'ja',
}) {
  if (locale == 'ja') {
    final ja = nameJa?.trim();
    if (ja != null && ja.isNotEmpty) {
      return ja;
    }
  }
  return nameEn;
}

/// 賦香率の表示名。
String concentrationLabel(String value) => switch (value) {
  'edc' => 'オーデコロン',
  'edt' => 'オードトワレ',
  'edp' => 'オードパルファム',
  'parfum' => 'パルファム',
  'extrait' => 'エクストレ',
  'cologne' => 'コロン',
  _ => '',
};
