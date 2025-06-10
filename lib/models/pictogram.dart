class Pictogram {
  final int id;
  final String keyword;
  final String imageUrl;
  final String description;
  final String category;

  Pictogram({
    required this.id,
    required this.keyword,
    required this.imageUrl,
    required this.description,
    required this.category,
  });

  factory Pictogram.fromJson(Map<String, dynamic> json) {
    return Pictogram(
      id: json['id'] as int,
      keyword: json['keyword'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
    };
  }
}
