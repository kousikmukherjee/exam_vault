import 'package:hive/hive.dart';

part 'pdf_document.g.dart';

@HiveType(typeId: 5)
class PdfDocument extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String filePath;

  @HiveField(3)
  late DateTime dateAdded;

  @HiveField(4)
  late int lastPage;

  @HiveField(5)
  late List<int> bookmarkedPages;

  PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.dateAdded,
    this.lastPage = 0,
    List<int>? bookmarkedPages,
  }) : bookmarkedPages = bookmarkedPages ?? [];
}
