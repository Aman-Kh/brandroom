// ignore_for_file: unnecessary_question_mark

import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../services/index.dart';
import '../serializers/blog.dart';

class Blog {
  final dynamic id;
  final String title;
  final String subTitle;
  final String date;
  final String content;
  final String author;
  final String imageFeature;
  final dynamic categoryId;
  final String excerpt;
  final String slug;
  final String authorImage;
  final List<String> audioUrls;
  final String videoUrl;
  final String link;
  final int commentCount;

  const Blog({
    this.id,
    this.title = '',
    this.subTitle = '',
    this.date = '',
    this.content = '',
    this.author = '',
    this.imageFeature = '',
    this.categoryId,
    this.excerpt = '',
    this.slug = '',
    this.authorImage = '',
    this.audioUrls = const <String>[],
    this.videoUrl = '',
    this.link = '',
    this.commentCount = 0,
  });

  const Blog.empty([this.id])
      : title = '',
        subTitle = '',
        date = '',
        author = '',
        content = '',
        imageFeature = '',
        categoryId = 0,
        excerpt = '',
        slug = '',
        audioUrls = const <String>[],
        videoUrl = '',
        authorImage = '',
        link = '',
        commentCount = 0;

  factory Blog.fromJson(Map<String, dynamic>? json) {
    switch (ServerConfig().type) {
      case ConfigType.woo:
      case ConfigType.opencart:
      case ConfigType.magento:
      case ConfigType.dokan:
      case ConfigType.presta:
      case ConfigType.wcfm:
      case ConfigType.wordpress:
      case ConfigType.mylisting:
      case ConfigType.listeo:
      case ConfigType.listpro:
        return Blog.fromWooJson(json!);
      case ConfigType.shopify:
        return Blog.fromShopifyJson(json!);
      case ConfigType.strapi:
        return Blog.fromStrapiJson(json!);
      case ConfigType.notion:
        return Blog.fromNotionJson(json!);
      case ConfigType.bigCommerce:
        return Blog.fromBigCommerceJson(json!);
      default:
        return const Blog.empty(0);
    }
  }

  Blog.fromShopifyJson(Map<String, dynamic> json)
      : id = json['id'],
        author = json['authorV2']['name'],
        title = json['title'],
        content = json['contentHtml'],
        imageFeature = json['image']['url'],
        date = DateFormat.yMMMMd()
            .add_Hm()
            .format(DateTime.parse(json['publishedAt']).toLocal()),
        categoryId = 0,
        excerpt = '',
        slug = '',
        subTitle = '',
        audioUrls = const <String>[],
        videoUrl = '',
        authorImage = '',
        link = json['onlineStoreUrl'],
        commentCount = 0;

  factory Blog.fromStrapiJson(Map<String, dynamic> json) {
    var model = SerializerBlog.fromJson(json);
    final id = model.id;
    final author = model.user?.displayName ?? '';
    final title = model.title ?? '';
    final subTitle = model.subTitle ?? '';
    final content = model.content ?? '';
    final imageFeature = ServerConfig().url + model.images!.first.url!;
    final date = model.date ?? '';
    return Blog(
      author: author,
      title: title,
      subTitle: subTitle,
      content: content,
      id: id,
      date: date,
      imageFeature: imageFeature,
    );
  }

  factory Blog.fromWooJson(Map<String, dynamic> json) {
    String? imageFeature;
    var imgJson = json['better_featured_image'];
    if (imgJson != null) {
      if (imgJson['media_details']?['sizes']?['medium_large'] != null) {
        imageFeature =
            imgJson['media_details']?['sizes']?['medium_large']?['source_url'];
      }
    }

    if (imageFeature == null) {
      var imgMedia = json['_embedded']?['wp:featuredmedia'];
      if (imgMedia is List && imgMedia.isNotEmpty) {
        imageFeature =
            imgMedia[0]['media_details']?['sizes']?['large']?['source_url'];
        imageFeature ??= imgMedia[0]['source_url'];
      }
    }

    final author = json['_embedded']?['author']?[0]['name'] ?? '';
    final date = Tools.formatDate(json['date']);
    final id = json['id'];
    final title = HtmlUnescape().convert(json['title']['rendered']);
    final subTitle = HtmlUnescape().convert(json['excerpt']['rendered']);
    final content = json['content']['rendered'];
    final categories = List.from(json['categories'] ?? []);
    final categoryId = categories.isNotEmpty ? categories.first : null;
    final excerpt = HtmlUnescape().convert(json['excerpt']['rendered']);
    final slug = json['slug'];
    final authorImage = json['_embedded']?['author']?[0]['avatar_urls']?['48'];
    final link = json['link'];
    final videoUrl = Videos.getVideoLink(content);

    final commentCount = List.from(json['_embedded']?['replies'] ?? []).length;

    return Blog(
      author: author,
      title: title,
      subTitle: subTitle,
      content: content,
      id: id,
      date: date,
      imageFeature: imageFeature ?? '',
      categoryId: categoryId,
      excerpt: excerpt,
      slug: slug,
      authorImage: authorImage ?? '',
      audioUrls: _parseAudioLink(content),
      videoUrl: videoUrl ?? '',
      link: link,
      commentCount: commentCount,
    );
  }

  factory Blog.fromNotionJson(Map<String, dynamic> json) {
    var img = NotionDataTools.fromFile(json['properties']['Image']);

    try {
      var id = json['id'];
      var title = HtmlUnescape()
          .convert(NotionDataTools.fromTitle(json['properties']['Name']) ?? '');
      var subTitle = json['subTitle'] ?? '';
      var date =
          Tools.formatDate(json['properties']['Created']['created_time']);
      var content = json['content'] ?? '';
      var author = json['properties']['Author']?['created_by']['name'];
      var authorImage =
          json['properties']['Author']?['created_by']['avatar_url'];

      var imageFeature = (img?.isNotEmpty ?? false) ? img!.first : '';
      var categoryId = 0;
      var excerpt = '';
      var slug = '';

      var audioUrls = const <String>[];
      var videoUrl = '';
      var link = json['url'];

      return Blog(
        author: author ?? '',
        title: title,
        subTitle: subTitle,
        content: content,
        id: id,
        date: date,
        imageFeature: imageFeature,
        categoryId: categoryId,
        excerpt: excerpt,
        slug: slug,
        authorImage: authorImage ?? '',
        audioUrls: audioUrls,
        videoUrl: videoUrl,
        link: link,
      );
    } catch (e, trace) {
      printLog(e);
      printLog(trace);
      rethrow;
    }
  }

  factory Blog.fromBigCommerceJson(Map<String, dynamic> json) {
    try {
      var id = json['id'];
      var title = HtmlUnescape().convert(json['title'] ?? '');
      var subTitle = json['subTitle'] ?? '';
      var date = Tools.formatDateToLocal(json['published_date']['date']);
      var content = json['body'] ?? '';
      var author = json['author'];

      var imageFeature = json['thumbnail_path'] ?? '';
      var categoryId = 0;
      var excerpt = '';
      var slug = '';

      var audioUrls = const <String>[];
      var videoUrl = '';
      var link = json['url'];

      return Blog(
        author: author ?? '',
        title: title,
        subTitle: subTitle,
        content: content,
        id: id,
        date: date,
        imageFeature: imageFeature,
        categoryId: categoryId,
        excerpt: excerpt,
        slug: slug,
        audioUrls: audioUrls,
        videoUrl: videoUrl,
        link: link,
      );
    } catch (e, trace) {
      printLog(e);
      printLog(trace);
      rethrow;
    }
  }

  static Future getBlogs({String? url, categories, page = 1}) async {
    try {
      var param = '_embed&page=$page';
      if (categories != null) {
        param += '&categories=$categories';
      }
      final response =
          await httpGet('$url/wp-json/wp/v2/posts?$param'.toUri()!);

      if (response.statusCode != 200) {
        return [];
      }
      return jsonDecode(response.body);
    } on Exception catch (_) {
      return [];
    }
  }

  bool get isAudioDetected => audioUrls.isNotEmpty;

  bool get isEmpty {
    return date == '' &&
        title == '' &&
        content == '' &&
        excerpt == '' &&
        imageFeature == '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subTitle': subTitle,
      'date': date,
      'content': content,
      'author': author,
      'imageFeature': imageFeature,
      'categoryId': categoryId ?? 0,
      'excerpt': excerpt,
      'slug': slug,
      'authorImage': authorImage,
      'audioUrls': audioUrls,
      'videoUrl': videoUrl,
      'link': link,
    };
  }

  factory Blog.fromLocalJson(Map<String, dynamic> json) {
    try {
      var id = json['id'];
      var title = json['title'];
      var subTitle = json['subTitle'];
      var date = json['date'];
      var content = json['content'];
      var author = json['author'];
      var imageFeature = json['imageFeature'];
      var categoryId = json['categoryId'] ?? 0;
      var excerpt = json['excerpt'];
      var slug = json['slug'];
      var authorImage = json['authorImage'];
      var audioUrls = List<String>.from(json['audioUrls'] ?? const <String>[]);
      var videoUrl = json['videoUrls'];
      var link = json['link'];

      return Blog(
        author: author,
        title: title,
        subTitle: subTitle,
        content: content,
        id: id,
        date: date,
        imageFeature: imageFeature ?? '',
        categoryId: categoryId,
        excerpt: excerpt,
        slug: slug,
        authorImage: authorImage ?? '',
        audioUrls: audioUrls,
        videoUrl: videoUrl ?? '',
        link: link,
      );
    } catch (e, trace) {
      printLog(e);
      printLog(trace);
      rethrow;
    }
  }

  Blog copyWith({
    dynamic? id,
    dynamic? categoryId,
    String? title,
    String? subTitle,
    String? date,
    String? content,
    String? author,
    String? imageFeature,
    String? excerpt,
    String? slug,
    String? authorImage,
    List<String>? audioUrls,
    String? videoUrl,
    String? link,
    int? commentCount,
  }) {
    return Blog(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      date: date ?? this.date,
      content: content ?? this.content,
      author: author ?? this.author,
      imageFeature: imageFeature ?? this.imageFeature,
      categoryId: categoryId ?? this.categoryId,
      excerpt: excerpt ?? this.excerpt,
      slug: slug ?? this.slug,
      authorImage: authorImage ?? this.authorImage,
      audioUrls: audioUrls ?? this.audioUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      link: link ?? this.link,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  @override
  String toString() => 'Blog { id: $id  title: $title}';

  static List<String> _parseAudioLink(String content) {
    /// Detect .mp3 URLs in post content.
    final regExp = RegExp(
      r'(https?|ftp|file)://(www.)?(.*?)\.(mp3|m4a)',
      multiLine: true,
      caseSensitive: false,
    );
    var matches = regExp.allMatches(content);

    /// Get audio URLs from RegExp matches
    final matchesGroup = matches.map((item) => item.group(0) ?? '').toList();

    /// Remove redundant URLs
    final audioList = matchesGroup.toSet().toList()..remove('');
    return audioList;
  }
}
