class Question {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final String? imageUrl;

  const Question({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    this.imageUrl,
  });

  // Factory constructor to create a Question from JSON
  factory Question.fromJson(Map<String, dynamic> json, {String? examId}) {
    // 複数のカテゴリーから主要なものを1つ選択
    String category = 'その他';
    if (json['categories'] is List) {
      final List<String> cats = List<String>.from(json['categories']);
      // UIで定義されているカテゴリー名にマッピング
      final mapping = {
        '潜水業務': '潜水業務',
        '送気、潜降及び浮上': '送気・器具',
        '送気・器具': '送気・器具',
        '高気圧障害': '高気圧障害',
        '関係法令': '法令',
        '法令': '法令',
      };

      for (var key in mapping.keys) {
        if (cats.contains(key)) {
          category = mapping[key]!;
          break;
        }
      }
      if (category == 'その他' && cats.isNotEmpty) {
        // マッピングにないがカテゴリーがある場合、最初のものを採用
        category = cats.first;
      }
    } else if (json['category'] != null) {
      category = json['category'] as String;
    }

    // IDがない場合は、試験IDと問題番号から生成
    String id = json['id']?.toString() ?? "";
    if (id.isEmpty && examId != null) {
      final noStr = json['no']?.toString() ?? "";
      final match = RegExp(r'\d+').firstMatch(noStr);
      final qNo = match?.group(0) ?? "0";
      id = "${examId}_$qNo";
    }

    return Question(
      id: id,
      category: category,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answerIndex: json['answer_index'] as int,
      explanation: json['explanation'] as String? ?? "",
      imageUrl: json['image_url'] as String?,
    );
  }

  // Method to convert a Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': options,
      'answer_index': answerIndex,
      'explanation': explanation,
      'image_url': imageUrl,
    };
  }

  // Helper for Database (SQLite/Supabase)
  Map<String, dynamic> toMap({bool forSupabase = false}) {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': forSupabase ? options : options.join('|||'),
      'answer_index': answerIndex,
      'explanation': explanation,
      'image_url': imageUrl,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    List<String> optionsList;
    if (rawOptions is List) {
      optionsList = List<String>.from(rawOptions);
    } else {
      optionsList = (rawOptions as String).split('|||');
    }

    return Question(
      id: map['id'] as String,
      category: map['category'] as String,
      question: map['question'] as String,
      options: optionsList,
      answerIndex: map['answer_index'] as int,
      explanation: map['explanation'] as String? ?? "",
      imageUrl: map['image_url'] as String?,
    );
  }
}
