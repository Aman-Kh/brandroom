import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:core';

import 'package:collection/collection.dart';
import 'package:quiver/strings.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/booking/staff_booking_model.dart';
import '../../../models/entities/brand.dart';
import '../../../models/entities/order_delivery_date.dart';
import '../../../models/entities/prediction.dart';
import '../../../models/index.dart';
import '../../../modules/dynamic_layout/helper/helper.dart';
import '../../../services/base_services.dart';
import '../../../services/https.dart';
import '../../../services/index.dart';
import 'woocommerce_api.dart';

const _rootCategoryId = 0;

const emptyShippingMsg =
    'There are no shipping options available. Please ensure that your address has been entered correctly, or contact us if you need any help.';
final String kDefaultCurrency =
    kAdvanceConfig.defaultCurrency?.currencyCode ?? 'USD';

class WooCommerceService extends BaseServices {
  Map<String, dynamic>? configCache;
  final WooCommerceAPI wcApi;

  final String isSecure;
  List<Category> categories = [];
  Map<String, Tag> tags = {};
  String? currentLanguage;
  bool? currentHideEmptyCategories;
  Map<String, List<Product>> categoryCache = <String, List<Product>>{};

  WooCommerceService({
    required String domain,
    String? blogDomain,
    required String consumerKey,
    required String consumerSecret,
  })  : wcApi = WooCommerceAPI(domain, consumerKey, consumerSecret),
        isSecure = domain.contains('https') ? '' : '&insecure=cool',
        super(domain: domain, blogDomain: blogDomain ?? domain) {
    configCache = null;
    categories = [];
    currentLanguage = null;
    currentHideEmptyCategories = null;
    categoryCache = <String, List<Product>>{};
  }

  Product jsonParser(item) {
    var product = Product.fromJson(item);
    if (item['store'] != null) {
      if (item['store']['errors'] == null) {
        product = Services().widget.updateProductObject(product, item);
      }
    }
    return product;
  }

  String buildUrlToGetProducts(String endPoint) {
    if (kAdvanceConfig.enableWOOCSCurrencySwitcher) {
      return endPoint.contains('?')
          ? '$endPoint&currency=$kDefaultCurrency'
          : '$endPoint?currency=$kDefaultCurrency';
    }
    return endPoint;
  }

  @override
  Future<List<Category>> getCategories({lang}) async {
    try {
      if (categories.isNotEmpty &&
          currentLanguage == lang &&
          currentHideEmptyCategories == kAdvanceConfig.hideEmptyCategories) {
        return categories;
      }
      currentLanguage = lang;
      currentHideEmptyCategories = kAdvanceConfig.hideEmptyCategories;
      var list = <Category>[];
      var isEnd = false;
      var page = 1;
      var limit = 100;

      while (!isEnd) {
        var categories =
            await getCategoriesByPage(lang: lang, page: page, limit: limit);
        if (categories.isEmpty || categories.length < limit - 1) {
          isEnd = true;
        }
        page = page + 1;
        list = [...list, ...categories];
      }
      categories = list;
      return list;
    } catch (e) {
      return [];
      //rethrow;
    }
  }

  @override
  Future<List<Category>> getCategoriesByPage({
    lang,
    page,
    limit,
    storeId,
    String? searchTerm,
    int? parent,
    bool useCompute = true,
  }) async {
    try {
      var url =
          'products/categories?exclude=$kExcludedCategory&per_page=$limit&page=$page&hide_empty=${kAdvanceConfig.hideEmptyCategories}';
      if (lang != null && kAdvanceConfig.isMultiLanguages) {
        url += '&lang=$lang';
      }
      if (searchTerm != null && searchTerm.isNotEmpty) {
        url += '&search=$searchTerm';
      }
      if (parent != null) {
        url += '&parent=$parent';
      }
      var response = await wcApi.getAsync(url);
      if (!useCompute) {
        return Category.parseCategoryList(response);
      }

      return Category.parseCategoryList(response);
    } catch (e) {
      //This error exception is about your RegetHomeCache(st API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts({userId}) async {
    try {
      var endpoint = 'products';
      if (userId != null) {
        endpoint += '?user_id=$userId';
      }
      var response = await wcApi.getAsync(endpoint);
      var list = <Product>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(jsonParser(item));
        }
        return list;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<Product>?> fetchProductsLayout({
    config,
    lang,
    userId,
    bool refreshCache = false,
  }) async {
    try {
      /// Load first page from cache.
      if (kAdvanceConfig.isCaching &&
          configCache != null &&
          (config['page'] == 1 || config['page'] == null)) {
        var obj;
        final horizontalLayout = configCache!['HorizonLayout'] as List?;
        if (horizontalLayout != null) {
          obj = horizontalLayout.firstWhere(
              (o) =>
                  o['layout'] == config['layout'] &&
                  ((o['category'] != null &&
                          o['category'] == config['category']) ||
                      (o['tag'] != null && o['tag'] == config['tag'])),
              orElse: () => null);
          if (obj != null && obj['data'].length > 0) return obj['data'];
        }

        final verticalLayout = configCache!['VerticalLayout'];
        if (verticalLayout != null &&
            verticalLayout['layout'] == config['layout'] &&
            ((verticalLayout['category'] != null &&
                    verticalLayout['category'] == config['category']) ||
                (verticalLayout['tag'] != null &&
                    verticalLayout['tag'] == config['tag']))) {
          return verticalLayout['data'];
        }
      }

      var endPoint = 'products?status=publish';
      if (kAdvanceConfig.isMultiLanguages) {
        endPoint += '&lang=$lang';
      }
      if (config.containsKey('category') && config['category'] != null) {
        endPoint += "&category=${config["category"]}";
      }
      if (config.containsKey('tag') && config['tag'] != null) {
        endPoint += "&tag=${config["tag"]}";
      }

      /// Add featured filter
      if (config.containsKey('featured') && config['featured'] != null) {
        endPoint += "&featured=${config["featured"]}";
      }

      /// Add onSale filter
      if (config.containsKey('onSale') &&
          config['onSale'] != null &&
          config['onSale']) {
        endPoint += "&on_sale=${config["onSale"]}";
      }

      if (config['minPrice'] != null &&
          config['maxPrice'] != null &&
          config['maxPrice'] > 0) {
        endPoint +=
            '&min_price=${(config['minPrice'] as double).toInt().toString()}&max_price=${(config['maxPrice'] as double).toInt().toString()}';
      }

      if (config['attribute'] != null) {
        endPoint += '&attribute=${config['attribute']}';
      }

      if (config['attributeId'] != null) {
        endPoint += '&attribute_term=${config['attributeId']}';
      }

      /// sort by
      if (config.containsKey('orderby') && config['orderby'] != null) {
        endPoint += "&orderby=${config["orderby"]}";
      }

      if (config.containsKey('order') && config['order'] != null) {
        endPoint += "&order=${config["order"]}";
      }

      if (config.containsKey('page')) {
        endPoint += "&page=${config["page"]}";
      }
      if (config.containsKey('limit')) {
        endPoint += "&per_page=${config["limit"] ?? apiPageSize}";
      }
      if (userId != null) {
        endPoint += '&user_id=$userId';
      }

      /// only load special products
      var include = config['include'];
      if (include != null && include is List) {
        var result = <int>[];
        for (var item in include) {
          /// check product is int type
          var idProduct = Helper.formatInt(item);
          if (idProduct != null) {
            result.add(idProduct);
          }
        }
        endPoint += '&include=${result.toList().join(',')}';
      }
      endPoint = buildUrlToGetProducts(endPoint);

      var response = await wcApi.getAsync(
        endPoint,
        refreshCache: refreshCache,
        version: 3,
      );

      if (response is Map && isNotBlank(response['message'])) {
        printLog('WooCommerce Error: ${response['message']}');
        return [];
      }

      return ProductModel.parseProductList(response, config);
    } catch (e, trace) {
      printLog(trace.toString());
      printLog(e.toString());
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      return [];
    }
  }

  /// get all attribute_term for selected attribute for filter menu
  @override
  Future<List<SubAttribute>> getSubAttributes({
    int? id,
    String? lang,
    int page = 1,
  }) async {
    try {
      return (await getSubAttributesByPage(
        id: id,
        page: page,
        lang: lang,
      ));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SubAttribute>> getSubAttributesByPage(
      {id, page, String? lang}) async {
    try {
      var listAttributes = <SubAttribute>[];

      var url =
          'products/attributes/$id/terms?per_page=100&page=$page&per_page=10';

      if (lang != null && kAdvanceConfig.isMultiLanguages) {
        url += '&lang=$lang';
      }

      var response = await wcApi.getAsync(url);

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          if (item['count'] > 0) {
            listAttributes.add(SubAttribute.fromJson(item));
          }
        }
        return listAttributes;
      }
    } catch (e) {
      rethrow;
    }
  }

  //get all attributes for filter menu
  @override
  Future<List<FilterAttribute>> getFilterAttributes({String? lang}) async {
    try {
      var list = <FilterAttribute>[];
      var endPoint = 'products/attributes';

      if (lang != null && kAdvanceConfig.isMultiLanguages) {
        endPoint += '?lang=$lang';
      }

      var response = await wcApi.getAsync(endPoint);

      for (var item in response) {
        list.add(FilterAttribute.fromJson(item));
      }

      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>?> fetchProductsByCategory(
      {categoryId,
      tagId,
      page = 1,
      minPrice,
      maxPrice,
      orderBy,
      lang,
      order,
      attribute,
      attributeTerm,
      featured,
      onSale,
      listingLocation,
      userId,
      String? include,
      String? search,
      nextCursor}) async {
    try {
      var list = <Product>[];

      /// this cause a bug on Profile List
      /// we just allow cache if the totalItem = perPageItem otherwise, should reload
      if ((page == 0 || page == 1) &&
          categoryCache['$categoryId'] != null &&
          categoryCache['$categoryId']!.isNotEmpty &&
          featured == null &&
          onSale == null &&
          attributeTerm == null) {
        if (categoryCache['$categoryId']!.length == apiPageSize) {
          return categoryCache['$categoryId'];
        }
      }

      var endPoint = 'products';

      if (include != null && include.isNotEmpty) {
        endPoint = 'products?include=$include';
      }

      if (include == null || include.isEmpty) {
        endPoint =
            'products?status=publish&per_page=$apiPageSize&page=$page&skip_cache=1';

        if (tagId != null && tagId != 'null') {
          endPoint += '&tag=$tagId';
        }
        if (minPrice != null && maxPrice != null && maxPrice > 0) {
          endPoint +=
              '&min_price=${(minPrice as double).toInt().toString()}&max_price=${(maxPrice as double).toInt().toString()}';
        }
        if (orderBy != null) {
          endPoint += '&orderby=$orderBy';
        }
        if (order != null) {
          endPoint += '&order=$order';
        }
        if (featured != null && featured) {
          endPoint += '&featured=$featured';
        }
        if (onSale != null && onSale) {
          endPoint += '&on_sale=$onSale';
        }
        if (attribute != null && attributeTerm != null) {
          endPoint += '&attribute=$attribute&attribute_term=$attributeTerm';
        }
        if (kAdvanceConfig.hideOutOfStock) {
          endPoint += '&stock_status=instock';
        }
        if (userId != null) {
          endPoint += '&user_id=$userId';
        }
        if (categoryId != null && categoryId != '-1' && categoryId != '0') {
          endPoint += '&category=$categoryId';
        }
      }

      if (kAdvanceConfig.isMultiLanguages && lang != null) {
        endPoint += '&lang=$lang';
      }

      if (search != null) {
        endPoint += '&search=$search';
      }
      endPoint = buildUrlToGetProducts(endPoint);
      printLog('-- fetchProductsByCategory --');
      printLog(endPoint);

      var response = await wcApi.getAsync(endPoint, version: 3);

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          var product = jsonParser(item);

          /// ignore the hidden catalog
          if (item['catalog_visibility'] == 'hidden') {
            continue;
          }

          if ((kAdvanceConfig.hideOutOfStock) && !product.inStock!) {
            /// hideOutOfStock product
            continue;
          }

          if (categoryId != null) {
            product.categoryId = categoryId;
          }
          list.add(product);
        }
        return list;
      }
    } catch (e, trace) {
      printLog(trace);
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<User?> loginFacebook({String? token}) async {
    const cookieLifeTime = 120960000000;

    try {
      var endPoint =
          '$domain/wp-json/api/flutter_user/fb_connect/?second=$cookieLifeTime'
          // ignore: prefer_single_quotes
          "&access_token=$token$isSecure";

      var response = await httpCache(endPoint.toUri()!);

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null ||
          jsonDecode['cookie'] == null ||
          jsonDecode['user'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<User> loginSMS({String? token}) async {
    try {
      var endPoint =
          '$domain/wp-json/api/flutter_user/firebase_sms_login/?phone=$token$isSecure';
      if (kAdvanceConfig.enableNewSMSLogin) {
        endPoint =
            // ignore: prefer_single_quotes
            "$domain/wp-json/api/flutter_user/firebase_sms_login_v2?phone=$token$isSecure";
      }

      var response = await httpGet(endPoint.toUri()!);

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null ||
          jsonDecode['cookie'] == null ||
          jsonDecode['user'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<User?> loginApple({String? token}) async {
    try {
      var endPoint = '$domain/wp-json/api/flutter_user/apple_login';

      var response = await httpPost(endPoint.toUri()!,
          body: convert.jsonEncode({'token': token}),
          headers: {'Content-Type': 'application/json'});

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null ||
          jsonDecode['cookie'] == null ||
          jsonDecode['user'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<Review>> getReviews(productId,
      {int page = 1, int perPage = 10}) async {
    try {
      var response =
          await wcApi.getAsync('products/$productId/reviews', version: 2);
      var list = <Review>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Review.fromJson(item));
        }
        return list;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future createReview(
      {String? productId, Map<String, dynamic>? data, String? token}) async {
    try {
      data!['product_id'] = productId;
      final response = await httpPost(
          '$domain/wp-json/api/flutter_woo/products/reviews'.toUri()!,
          body: convert.jsonEncode(data),
          headers: {'User-Cookie': token!, 'Content-Type': 'application/json'});
      var body = convert.jsonDecode(response.body);

      if (body['message'] == null) {
        return 'success';
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<ProductVariation>> getProductVariations(Product product,
      {String? lang = 'en'}) async {
    try {
      final list = <ProductVariation>[];
      var page = 1;

      while (true) {
        var endPoint =
            'products/${product.id}/variations?per_page=100&page=$page';
        if (kAdvanceConfig.isMultiLanguages) {
          endPoint += '&lang=$lang';
        }
        endPoint = buildUrlToGetProducts(endPoint);
        var response = await wcApi.getAsync(endPoint);
        if (response is Map && isNotBlank(response['message'])) {
          throw Exception(response['message']);
        } else {
          for (var item in response) {
            if (item['visible']) {
              list.add(ProductVariation.fromJson(item));
            }
          }

          if (response is List && response.length < 100) {
            /// No more data.
            break;
          }

          /// Fetch next page.
          page++;
        }
      }

      return list;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<ShippingMethod>> getShippingMethods({
    CartModel? cartModel,
    String? token,
    String? checkoutId,
    Store? store,
    String? langCode,
  }) async {
    try {
      if (isBookingProduct(cartModel!)) {
        return getShippingMethodsByWooApi();
      }
      var params = Order().toJson(cartModel, null, false);
      if (kVendorConfig['DisableVendorShipping'] == false &&
          ServerConfig().isVendorType()) {
        List lineItems = params['line_items'];
        for (var element in lineItems) {
          final product = cartModel.item[element['product_id']];
          if ((store == null && product!.store == null) ||
              (store != null &&
                  product!.store != null &&
                  product.store!.id == store.id)) {
            params['line_items'] = [element];
          }
        }
      }
      var list = <ShippingMethod>[];
      final response = await httpPost(
          // '$domain/wp-json/api/flutter_woo/shipping_methods?lang=$langCode'
          '$domain/wp-json/api/flutter_woo/shipping_methods'.toUri()!,
          body: convert.jsonEncode(params),
          headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 502) {
        return getShippingMethodsByWooApi();
      }

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        for (var item in body) {
          list.add(ShippingMethod.fromJson(item));
        }
      } else if (body['data'] != null &&
          body['data']['required_shipping'] != null) {
        if (body['data']['required_shipping'] == false) {
          return list;
        } else {
          throw Exception(emptyShippingMsg);
        }
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      if (list.isEmpty) {
        throw Exception(emptyShippingMsg);
      }
      return list;
    } catch (err) {
      rethrow;
    }
  }

  bool isBookingProduct(CartModel cartModel) {
    var isBooking = false;
    for (var key in cartModel.productsInCart.keys) {
      var productId = Product.cleanProductID(key);
      var product = cartModel.item[productId]!;
      if (product.bookingInfo != null) {
        isBooking = true;
      }
    }
    return isBooking;
  }

  Future<List<ShippingMethod>> getShippingMethodsByWooApi() async {
    try {
      var list = <ShippingMethod>[];
      var res = await wcApi.getAsync('shipping/zones');
      if (res is Map && isNotBlank(res['message'])) {
        throw Exception(res['message']);
      } else if (res is List && res.isNotEmpty) {
        await Future.forEach(res, (zone) async {
          final zoneId = zone is Map ? zone['id'] : 0;
          var response = await wcApi.getAsync('shipping/zones/$zoneId/methods');
          if (response is Map && isNotBlank(response['message'])) {
            throw Exception(response['message']);
          } else {
            for (var item in response) {
              var methodItem = {
                'id': item['instance_id'],
                'method_id': item['method_id'],
                'instance_id': item['instance_id'],
                'label': item['title'],
                'cost': item['settings']['cost'] != null &&
                        item['settings']['cost']['value'] != null
                    ? item['settings']['cost']['value']
                    : 0,
                'shipping_tax': 0
              };
              list.add(ShippingMethod.fromJson(methodItem));
            }
          }
        });
      }

      if (list.isEmpty) {
        throw Exception(emptyShippingMsg);
      }
      return list;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods({
    CartModel? cartModel,
    ShippingMethod? shippingMethod,
    String? token,
    String? langCode,
  }) async {
    try {
      if (isBookingProduct(cartModel!)) {
        return getPaymentMethodsByWooApi();
      }

      final params = Order().toJson(cartModel, null, false);

      var list = <PaymentMethod>[];
      final response = await httpPost(
          // '$domain/wp-json/api/flutter_woo/payment_methods?lang=$langCode'
          '$domain/wp-json/api/flutter_woo/payment_methods'.toUri()!,
          body: convert.jsonEncode(params),
          headers: {
            'Content-Type': 'application/json',
            'User-Cookie': token ?? '',
          });

      if (response.statusCode == 502) {
        return getPaymentMethodsByWooApi();
      }

      final body = convert.jsonDecode(response.body);

      if (response.statusCode == 200) {
        for (var item in body) {
          list.add(PaymentMethod.fromJson(item));
        }
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return list;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<PaymentMethod>> getPaymentMethodsByWooApi() async {
    try {
      var list = <PaymentMethod>[];
      var response = await wcApi.getAsync('payment_gateways');
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          if (item['enabled'] == true &&
              item['id'] != 'wc-appointment-gateway') {
            var methodItem = {
              'id': item['id'],
              'title': item['method_title'],
              'method_title': item['instance_id'],
              'description': item['description']
            };
            list.add(PaymentMethod.fromJson(methodItem));
          }
        }
      }
      return list;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Order>> getMyOrders({
    User? user,
    dynamic cursor,
    String? cartId,
  }) async {
    try {
      var response = await wcApi.getAsync(
          'orders?customer=${user!.id}&per_page=20&page=$cursor&order=desc&orderby=id&dummy=${DateTime.now().millisecondsSinceEpoch}');
      var list = <Order>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Order.fromJson(item));
        }
        return PagingResponse(data: list);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<OrderNote>> getOrderNote(
      {String? userId, String? orderId}) async {
    try {
      var response = await wcApi.getAsync(
          'orders/$orderId/notes?customer=$userId&per_page=20&type=${kAdvanceConfig.orderNotesWithPrivateNote == true ? 'any' : 'customer'}');
      var list = <OrderNote>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
//          if (item.type == 'any') {
          /// it is possible to update to `any` note
          /// ref: https://woocommerce.github.io/woocommerce-rest-api-docs/#list-all-order-notes
          list.add(OrderNote.fromJson(item));
//          }
        }
        return list;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Order> createOrder(
      {CartModel? cartModel,
      UserModel? user,
      bool? paid,
      String? transactionId}) async {
    try {
      final params = Order()
          .toJson(cartModel!, user!.user != null ? user.user!.id : null, paid);
      if (transactionId != null) {
        params['transaction_id'] = transactionId;
      }

      final response = await httpPost(
          '$domain/wp-json/api/flutter_order/create'.toUri()!,
          body: convert.jsonEncode(params),
          headers: {
            'User-Cookie': user.user != null ? user.user!.cookie! : '',
            'Content-Type': 'application/json'
          });
      var body = convert.jsonDecode(response.body);
      if (response.statusCode == 201 && body['message'] == null) {
        if (cartModel.shippingMethod == null &&
            kPaymentConfig.enableShipping &&
            body['shipping_lines'].length > 0) {
          body['shipping_lines'][0]['method_title'] = null;
        }
        return Order.fromJson(body);
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future updateOrder(orderId, {status, token}) async {
    try {
      final response = await httpPut(
          '$domain/wp-json/api/flutter_order/update/$orderId'.toUri()!,
          body: convert.jsonEncode({'status': status}),
          headers: token != null
              ? {
                  'User-Cookie': token,
                  'Content-Type': 'application/json',
                }
              : {});

      var body = convert.jsonDecode(response.body);
      if (body['message'] != null) {
        throw Exception(body['message']);
      } else {
        return Order.fromJson(body);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Order?> cancelOrder({Order? order, String? userCookie}) async {
    final newOrder = await Services()
        .api
        .updateOrder(order!.id, status: 'cancelled', token: userCookie);
    return newOrder;
  }

  Future<PagingResponse<Product>> ajaxSearch(String name) async {
    var list = <Product>[];

    printLog('${kAdvanceConfig.ajaxSearchURL}$name');

    final response =
        await httpPost('${kAdvanceConfig.ajaxSearchURL}$name'.toUri()!);
    final body = convert.jsonDecode(response.body);

    if (body is List) {
      for (var item in body) {
        var product = Product.fromAjaxSearch(item['asp_data']);
        list.add(product);
      }
    }
    return PagingResponse(data: list);
  }

  @override
  Future<PagingResponse<Product>> searchProducts({
    name,
    categoryId = '',
    categoryName,
    tag = '',
    attribute = '',
    attributeId = '',
    page,
    lang,
    listingLocation = '',
    userId,
  }) async {
    try {
      if (kAdvanceConfig.ajaxSearchURL.isNotEmpty) {
        return ajaxSearch(name);
      }

      var endPoint = 'products?status=publish&page=$page&per_page=$apiPageSize';

      if ((lang?.isNotEmpty ?? false) && kAdvanceConfig.isMultiLanguages) {
        endPoint += '&lang=$lang';
      }

      if (categoryId != null) {
        endPoint += '&category=$categoryId';
      }

      if (attribute != null) {
        endPoint += '&attribute=$attribute';
      }

      if (attributeId != null) {
        endPoint += '&attribute_term=$attributeId';
      }

      if (tag != null) {
        endPoint += '&tag=$tag';
      }
      if (userId != null) {
        endPoint += '&user_id=$userId';
      }
      endPoint = buildUrlToGetProducts(endPoint);
      var response = await wcApi.getAsync('$endPoint&search=$name');
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        var list = <Product>[];
        for (var item in response) {
          /// ignore the hidden catalog
          if (item['catalog_visibility'] == 'hidden') {
            continue;
          }

          if (!kAdvanceConfig.hideOutOfStock || item['in_stock']) {
            list.add(jsonParser(item));
          }
        }

        /// Search by SKU.
        if (kAdvanceConfig.enableSkuSearch) {
          var skuList = <Product>[];
          var response = await wcApi.getAsync('$endPoint&sku=$name');
          if (response is List) {
            for (var item in response) {
              if (!kAdvanceConfig.hideOutOfStock || item['in_stock']) {
                skuList.add(jsonParser(item));
              }
            }

            if (skuList.isNotEmpty) {
              /// Merge results. Let SKU results on top.
              skuList.addAll(list);
              return PagingResponse(data: skuList);
            }
          }
        }
        return PagingResponse(data: list);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  /// Auth
  @override
  Future<User?> getUserInfo(cookie) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      final response = await httpGet(
          '$domain/wp-json/api/flutter_user/get_currentuserinfo?token=$base64Str&$isSecure'
              .toUri()!);
      final body = convert.jsonDecode(response.body);
      if (body['user'] != null) {
        var user = body['user'];
        return User.fromAuthUser(user, cookie);
      } else {
        if (body['message'] != 'Invalid cookie') {
          throw Exception(body['message']);
        }
        return null;

        /// we may handle if Invalid cookie here
      }
    } catch (err) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserInfo(
      Map<String, dynamic> json, String? token) async {
    try {
      final body = convert.jsonEncode({...json, 'cookie': token});

      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/update_user_profile'.toUri()!,
          body: body,
          headers: {'Content-Type': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        data['cookie'] = token;
        return data;
      } else if (data['message'] != null) {
        throw Exception(data['message']);
      } else {
        throw Exception('Can not update user info');
      }
    } catch (err) {
      rethrow;
    }
  }

  /// Create a New User
  @override
  Future<User?> createUser({
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    String? phoneNumber,
    bool isVendor = false,
  }) async {
    try {
      var niceName = '${firstName!} ${lastName!}';
      var endpoint =
          '$domain/wp-json/api/flutter_user/sign_up/?insecure=cool&$isSecure'
              .toUri()!;
      if (kAdvanceConfig.enableNewSMSLogin) {
        endpoint =
            '$domain/wp-json/api/flutter_user/sign_up_2/?insecure=cool&$isSecure'
                .toUri()!;
      }
      final response = await httpPost(endpoint,
          body: convert.jsonEncode({
            'user_email': username,
            'user_login': username,
            'username': username,
            'user_pass': password,
            'email': username,
            'user_nicename': niceName,
            'display_name': niceName,
            'phone': phoneNumber,
            'first_name': firstName,
            'last_name': lastName,
          }),
          headers: {'Content-Type': 'application/json'});
      var body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body['message'] == null) {
        var cookie = body['cookie'];
        return await getUserInfo(cookie);
      } else {
        var message = body['message'];
        throw Exception(message ?? 'Can not create the user.');
      }
    } catch (err) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  /// login
  @override
  Future<User?> login({username, password}) async {
    var cookieLifeTime = 120960000000;
    try {
      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/generate_auth_cookie/?insecure=cool&$isSecure'
              .toUri()!,
          body: convert.jsonEncode({'seconds': cookieLifeTime.toString(), 'username': username, 'password': password}),
          headers: {'Content-Type': 'application/json'});

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && isNotBlank(body['cookie'])) {
        return await getUserInfo(body['cookie']);
      } else if (body['code'] == 'pending_approval') {
        throw ('The account is pending approval.');
      } else {
        throw ('The username or password is incorrect.');
      }
    } catch (err, trace) {
      printLog('🔥 Integration error:');
      printLog(err);
      printLog(trace);
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<Stream<Product>> streamProductsLayout({required config}) async {
    try {
      var endPoint = 'products?per_page=$apiPageSize';
      if (config.containsKey('category')) {
        endPoint += "&category=${config["category"]}";
      }
      if (config.containsKey('tag')) {
        endPoint += "&tag=${config["tag"]}";
      }
      endPoint = buildUrlToGetProducts(endPoint);
      var response = await wcApi.getStream(endPoint);

      return response.stream
          .transform(utf8.decoder)
          .transform(json.decoder)
          .expand((data) => (data as List))
          .map(jsonParser);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Product?> getProduct(id, {lang}) async {
    try {
      var endpoint = (lang == null || !kAdvanceConfig.isMultiLanguages)
          ? 'products/$id'
          : 'products/$id?lang=$lang';
      endpoint = buildUrlToGetProducts(endpoint);
      var response = await wcApi.getAsync(endpoint);

      if (response is Map && isNotBlank(response['message'])) {
        printLog('GetProduct Error: ${response['message']}');
        return null;
      }

      return jsonParser(response);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<ProductVariation?> getVariationProduct(id, variationId, {lang}) async {
    try {
      var endpoint = (lang == null || !kAdvanceConfig.isMultiLanguages)
          ? 'products/$id/variations/$variationId'
          : 'products/$id/variations/$variationId?lang=$lang';
      endpoint = buildUrlToGetProducts(endpoint);
      var response = await wcApi.getAsync(endpoint);

      if (response is Map && isNotBlank(response['message'])) {
        printLog('GetProduct Error: ${response['message']}');
        return null;
      }

      return ProductVariation.fromJson(response);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Coupons> getCoupons({int page = 1, String search = ''}) async {
    try {
      var response = await wcApi.getAsync(
          'coupons?page=$page${search.isNotEmpty ? '&search=$search' : ''}');
      //printLog(response.toString());
      return Coupons.getListCoupons(response);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getHomeCache(String? lang) async {
    try {
      final data = await wcApi.getAsync('flutter/cache?lang=$lang');
      if (data == null || data is! Map) {
        throw Exception("Can't get home cache");
      }
      if (data['message'] != null) {
        throw Exception(data['message']);
      }
      var config = Map<String, dynamic>.from(data);
      if (config['HorizonLayout'] != null) {
        var horizontalLayout = config['HorizonLayout'] as List;
        List<dynamic>? items = [];
        List<dynamic>? products = [];
        List<Product> list;
        for (var i = 0; i < horizontalLayout.length; i++) {
          if (horizontalLayout[i]['radius'] != null) {
            horizontalLayout[i]['radius'] =
                double.parse("${horizontalLayout[i]["radius"]}");
          }
          if (horizontalLayout[i]['size'] != null) {
            horizontalLayout[i]['size'] =
                double.parse("${horizontalLayout[i]["size"]}");
          }
          if (horizontalLayout[i]['padding'] != null) {
            horizontalLayout[i]['padding'] =
                double.parse("${horizontalLayout[i]["padding"]}");
          }

          products = horizontalLayout[i]['data'] as List?;
          list = [];
          if (products != null &&
              products.isNotEmpty &&
              horizontalLayout[i]['layout'] != 'story') {
            for (var item in products) {
              var product = jsonParser(item);
              if ((kAdvanceConfig.hideOutOfStock) && !product.inStock!) {
                /// hideOutOfStock product
                continue;
              }
              if (horizontalLayout[i]['category'] != null &&
                  "${horizontalLayout[i]["category"]}".isNotEmpty) {
                product.categoryId = horizontalLayout[i]['category'].toString();
              }
              list.add(product);
            }
          }
          horizontalLayout[i]['data'] = list;

          items = horizontalLayout[i]['items'] as List?;
          if (items != null && items.isNotEmpty) {
            for (var j = 0; j < items.length; j++) {
              if (items[j]['padding'] != null) {
                items[j]['padding'] = double.parse("${items[j]["padding"]}");
              }

              var listProduct = <Product>[];
              var prods = items[j]['data'] as List?;
              if (prods != null && prods.isNotEmpty) {
                for (var prod in prods) {
                  var product = jsonParser(prod);
                  if ((kAdvanceConfig.hideOutOfStock) && !product.inStock!) {
                    /// hideOutOfStock product
                    continue;
                  }
                  listProduct.add(product);
                }
              }
              items[j]['data'] = listProduct;
            }
          }
        }

        if (config['VerticalLayout'] != null &&
            config['VerticalLayout']['data'] != null) {
          var products = config['VerticalLayout']['data'] as List?;
          var list = <Product>[];
          if (products != null && products.isNotEmpty) {
            for (var item in products) {
              var product = jsonParser(item);
              if ((kAdvanceConfig.hideOutOfStock) && !product.inStock!) {
                /// hideOutOfStock product
                continue;
              }
              list.add(product);
            }
          }
          config['VerticalLayout']['data'] = list;
        }
        configCache = config;
        return config;
      }
      return null;
    } catch (e, trace) {
      printLog(trace);
      printLog(e);
      return null;
    }
  }

  @override
  Future<User?> loginGoogle({String? token}) async {
    const cookieLifeTime = 120960000000;

    try {
      var endPoint =
          '$domain/wp-json/api/flutter_user/google_login/?second=$cookieLifeTime'
                  '&access_token=$token$isSecure'
              .toUri()!;

      var response = await httpGet(endPoint);

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null ||
          jsonDecode['cookie'] == null ||
          jsonDecode['user'] == null) {
        throw Exception(jsonDecode['message']);
      }
      return User.fromWooJson(jsonDecode);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  /// This layout only suitable for the small Categories items
  @override
  Future getCategoryWithCache() async {
    List<Category> getSubCategories(id) {
      return categories.where((o) => o.parent == id).toList();
    }

    bool hasChildren(id) {
      return categories.where((o) => o.parent == id).toList().isNotEmpty;
    }

    List<Category> getParentCategory() {
      return categories.where((item) => item.parent == '0').toList();
    }

    var categoryIds = <String>[];
    var parentCategories = getParentCategory();
    for (var item in parentCategories) {
      if (hasChildren(item.id)) {
        var subCategories = getSubCategories(item.id);
        for (var item in subCategories) {
          categoryIds.add(item.id.toString());
        }
      } else {
        categoryIds.add(item.id.toString());
      }
    }

    return await getCategoryCache(categoryIds);
  }

  Future<Map<String, dynamic>> getCategoryCache(categoryIds) async {
    try {
      final data = await wcApi.getAsync(
          'flutter/category/cache?categoryIds=${List<String>.from(categoryIds).join(",")}');
      if (data != null) {
        for (var i = 0; i < categoryIds.length; i++) {
          var productsJson = data['${categoryIds[i]}'] as List?;
          var list = <Product>[];
          if (productsJson != null && productsJson.isNotEmpty) {
            for (var item in productsJson) {
              var product = jsonParser(item);
              product.categoryId = categoryIds[i];
              list.add(product);
            }
          }
          categoryCache['${categoryIds[i]}'] = list;
        }
      }

      return categoryCache;
    } catch (e, trace) {
      printLog(trace.toString());
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<FilterTag>> getFilterTags({String? lang}) async {
    try {
      var list = <FilterTag>[];
      var url = 'products/tags';

      if (lang != null && kAdvanceConfig.isMultiLanguages) {
        url += '?lang=$lang';
      }

      var response = await wcApi.getAsync(url);

      for (var item in response) {
        list.add(FilterTag.fromJson(item));
      }

      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> getCheckoutUrl(
      Map<String, dynamic> params, String? lang) async {
    try {
      var str = convert.jsonEncode(params);
      var bytes = convert.utf8.encode(str);
      var base64Str = convert.base64.encode(bytes);

      final response =
          await httpPost('$domain/wp-json/api/flutter_user/checkout'.toUri()!,
              body: convert.jsonEncode({
                'order': base64Str,
              }),
              headers: {'Content-Type': 'application/json'});
      var body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body is String) {
        final webParam = UniversalPlatform.isWeb ? '&platform=web' : '';

        if (kPaymentConfig.enableOnePageCheckout ||
            kPaymentConfig.nativeOnePageCheckout ||
            kPaymentConfig.guestCheckout ||
            params['token'] == null) {
          var checkoutPageSlug =
              Map<String, dynamic>.from(kPaymentConfig.checkoutPageSlug);
          String? slug = checkoutPageSlug[lang!];
          slug ??= checkoutPageSlug.values.toList().first;
          slug = slug!.contains('?') ? '$slug&' : '$slug?';
          printLog('$domain/${slug}code=$body&mobile=true$webParam');
          return '$domain/${slug}code=$body&mobile=true$webParam';
        } else {
          return '$domain/mstore-checkout?code=$body&mobile=true$webParam';
        }
      } else {
        var message = body['message'];
        throw Exception(message ?? "Can't save the order to website");
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<String> submitForgotPassword(
      {String? forgotPwLink, Map<String, dynamic>? data}) async {
    try {
      var endpoint = '$domain/wp-json/api/flutter_user/reset-password'.toUri()!;
      var response = await httpPost(endpoint,
          body: convert.jsonEncode(data),
          headers: {'Content-Type': 'application/json'});
      var result = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return '';
      } else {
        return result['message'];
      }
    } catch (e) {
      printLog(e);
      return 'Unknown Error: $e';
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrencyRate() async {
    try {
      final url = kAdvanceConfig.enableWOOCSCurrencySwitcher
          ? '$domain/wp-json/woocs/v3/currency'
          : '$domain/wp-json/api/flutter_user/get_currency_rates';
      //todo:
      // new fix / remove httpcache to fix prices caching if they are on currency mode.
      // final response = await httpGet(url.toUri()!);
      final response = await httpCache(url.toUri()!);
      var body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body != null && body is Map) {
        var data = Map<String, dynamic>.from(body);
        var currency = <String, dynamic>{};
        for (var key in data.keys) {
          currency[key.toUpperCase()] =
              double.parse("${data[key]['rate'] == 0 ? 1 : data[key]['rate']}");
        }
        return currency;
      } else {
        return null;
      }
    } catch (err) {
      return null;
    }
  }

  @override
  Future getCountries() async {
    try {
      final response = await httpCache(
          '$domain/wp-json/api/flutter_user/get_countries'.toUri()!);
      var body = convert.jsonDecode(response.body);
      return body;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future getStatesByCountryId(countryId) async {
    try {
      final response = await httpGet(
          '$domain/wp-json/api/flutter_user/get_states?country_code=$countryId'
              .toUri()!);
      var body = convert.jsonDecode(response.body);
      return body;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<List<dynamic>?>? getCartInfo(String? token) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(token!);
      final response = await httpGet(
          '$domain/wp-json/api/flutter_woo/cart?token=$base64Str'.toUri()!);
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future syncCartToWebsite(CartModel cartModel, User? user) async {
    try {
      final params = Order()
          .toJson(cartModel, cartModel.user != null ? user!.id : null, false);

      final response = await httpPost(
          '$domain/wp-json/api/flutter_woo/cart'.toUri()!,
          body: convert.jsonEncode(params),
          headers: {'Content-Type': 'application/json'});
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerInfo(String? id) async {
    try {
      final response = await wcApi.getAsync('customers/$id');
      if (response['message'] != null) {
        throw Exception(response['message']);
      }
      if (response['billing'] != null) {
        final address = Address.fromJson(response);
        final billing = Address.fromJson(response['billing']);
        billing.firstName =
            billing.firstName!.isEmpty ? address.firstName : billing.firstName;
        billing.lastName =
            billing.lastName!.isEmpty ? address.lastName : billing.lastName;
        billing.email = billing.email!.isEmpty ? address.email : billing.email;
        if (billing.country!.isEmpty) {
          billing.country = kPaymentConfig.defaultCountryISOCode;
        }
        if (billing.state!.isEmpty) {
          billing.state = kPaymentConfig.defaultStateISOCode;
        }
        response['billing'] = billing;
      }
      return response;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getTaxes(CartModel cartModel) async {
    try {
      if (isBookingProduct(cartModel)) return null;
      final params = Order().toJson(
          cartModel, cartModel.user != null ? cartModel.user!.id : null, false);

      final response = await httpPost(
          '$domain/wp-json/api/flutter_woo/taxes'.toUri()!,
          body: convert.jsonEncode(params),
          headers: {'Content-Type': 'application/json'});
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        var taxes = <Tax>[];
        body['items'].forEach((item) {
          taxes.add(Tax.fromJson(item));
        });
        return {'items': taxes, 'total': body['taxes_total']};
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Tag>> getTagsByPage({
    String? lang,
    int? page,
    required int limit,
  }) async {
    try {
      var url =
          'products/tags?per_page=$limit&page=$page&hide_empty=${kAdvanceConfig.hideEmptyTags}';
      if (lang != null && kAdvanceConfig.isMultiLanguages) {
        url += '&lang=$lang';
      }
      var response = await wcApi.getAsync(url);

      final listTags = Tag.parseTagList(response);
      return PagingResponse(data: listTags);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Tag> getTagById({required tagId}) async {
    try {
      var url = 'products/tags/$tagId';
      var response = await wcApi.getAsync(url);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        return Tag.fromJson(response);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Tag?> getTagBySlug(String slug) async {
    try {
      var url = 'products/tags?slug=$slug';
      var response = await wcApi.getAsync(url);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        final tagItem = List.from(response).firstOrNull;
        if (tagItem == null) throw 'This tag does not exist';
        return Tag.fromJson(tagItem);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<bool> pushNotification(cookie,
      {receiverEmail, senderName, message}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      final endpoint = '$domain/wp-json/api/flutter_user/notification';
      final res = await httpPost(endpoint.toUri()!, body: {
        'token': base64Str,
        'receiver': receiverEmail,
        'sender': senderName,
        'message': message,
      });
      if (res.statusCode == 200) {
        return true;
      } else {
        throw Exception(res.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Order>>? getVendorOrders(
      {required User user, dynamic cursor = 1}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(user.cookie!);
      final response = await httpGet(
          '$domain/wp-json/wc/v2/flutter/vendor-orders?page=$cursor&per_page=25&token=$base64Str'
              .toUri()!);
      printLog(
          '$domain/wp-json/wc/v2/flutter/vendor-orders?page=$cursor&token=$base64Str'
              .toUri());
      var body = convert.jsonDecode(response.body);
      var list = <Order>[];
      if (body is Map && isNotBlank(body['message'])) {
        throw Exception(body['message']);
      } else {
        for (var item in body) {
          list.add(Order.fromJson(item));
        }
        return PagingResponse(data: list);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Product> createProduct(
      String? cookie, Map<String, dynamic> data) async {
    try {
      final response = await httpPost(
          '$domain/wp-json/api/flutter_multi_vendor/product'.toUri()!,
          body: convert.jsonEncode(data),
          headers: {
            'User-Cookie': cookie!,
            'Content-Type': 'application/json'
          });
      var body = convert.jsonDecode(response.body);
      if (body['message'] == null) {
        return jsonParser(body);
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>> getOwnProducts(String? cookie,
      {int? page, int? perPage}) async {
    try {
      var endPoint = '$domain/wp-json/api/flutter_multi_vendor/products/owner';
      endPoint = buildUrlToGetProducts(endPoint);
      final response = await httpPost(endPoint.toUri()!,
          body: convert.jsonEncode({'cookie': cookie, 'page': page}),
          headers: {
            'User-Cookie': cookie!,
            'Content-Type': 'application/json'
          });
      var body = convert.jsonDecode(response.body);
      if (body is Map && isNotBlank(body['message'])) {
        throw Exception(body['message']);
      } else {
        var list = <Product>[];
        for (var item in body) {
          list.add(jsonParser(item));
        }
        return list;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<dynamic> uploadImage(dynamic data, String? token) async {
    try {
      final response = await httpPost(
          '$domain/wp-json/api/flutter_multi_vendor/media'.toUri()!,
          body: convert.jsonEncode(data),
          headers: {'User-Cookie': token!, 'Content-Type': 'application/json'});
      var body = convert.jsonDecode(response.body);
      if (body['message'] == null) {
        return body;
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Point?> getMyPoint(String? token) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(token!);
      final response = await httpGet(
          '$domain/wp-json/api/flutter_woo/points?token=$base64Str'.toUri()!);
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Point.fromJson(body);
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future updatePoints(String? token, Order? order) async {
    try {
      final response = await httpPatch(
          '$domain/wp-json/api/flutter_woo/points'.toUri()!,
          body: convert.jsonEncode({'cookie': token, 'order_id': order!.id}));
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<BookStatus>? bookService({userId, value, message}) => null;

  @override
  Future<List<Product>> getProductNearest(location) async {
    try {
      var list = <Product>[];
      var lat = location.latitude;
      var long = location.longitude;
      var urlReq =
          '$domain/wp-json/wp/v2/${DataMapping().kProductPath}?status=publish&_embed=true';
      if (lat != 0 || long != 0) {
        urlReq += '&isGetLocate=true&lat=$lat&long=$long';
      }
      final response = await httpGet(urlReq.toUri()!);
      if (response.statusCode == 200) {
        for (var item in convert.jsonDecode(response.body)) {
          var product = Product.fromListingJson(item);
          var gallery = <String>[];
          for (var item in product.images) {
            if (!item.contains('http')) {
              var res =
                  await httpGet('$domain/wp-json/wp/v2/media/$item'.toUri()!);
              gallery.add(convert.jsonDecode(res.body)['source_url']);
            } else {
              gallery.add(item);
            }
          }
          product.images = gallery;
          list.add(product);
        }
      }
      printLog('getProductNearest');
      return list;
    } catch (err) {
      printLog('err at getProductRecents func ${err.toString()}');
      rethrow;
    }
  }

  @override
  Future<List<ListingBooking>> getBooking({userId, page, perPage}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> createBooking(dynamic bookingInfo) async {
    if (bookingInfo.isAvaliableOrder && bookingInfo.isEmpty == false) {
      final response = await httpPost(
          '$domain/wp-json/api/flutter_booking/checkout'.toUri()!,
          body: convert.jsonEncode(bookingInfo.toJsonAPI()),
          headers: {'Content-Type': 'application/json'});

      var body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body['appointment'] != null) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  @override
  Future<List<StaffBookingModel>> getListStaff(String? idProduct) async {
    final urlAPI = wcApi.getOAuthURLExternal(
        '$domain/wp-json/api/flutter_booking/get_staffs?product_id=$idProduct');

    final response = await httpCache(urlAPI.toUri()!);

    var body = convert.jsonDecode(response.body);
    if (response.statusCode == 200) {
      final listStaff = <StaffBookingModel>[];
      if (body is List) {
        if (body.isNotEmpty) {
          for (var staff in body) {
            if (staff != null) {
              listStaff.add(StaffBookingModel.fromJson(staff));
            }
          }
        }
      }
      return listStaff;
    } else {
      return [];
    }
  }

  @override
  Future<List<String>> getSlotBooking(
      String? idProduct, String idStaff, String date) async {
    var urlAPI =
        '$domain/wp-json/api/flutter_booking/get_slots?product_id=$idProduct&date=$date';

    if ((idStaff.isNotEmpty) && idStaff != 'null') {
      urlAPI += '&staff_ids=$idStaff';
    }

    final response = await httpGet(urlAPI.toUri()!);
    if (response.body.isNotEmpty) {
      final listSlot = <String>[];
      final result = convert.jsonDecode(response.body);
      if (result is List) {
        for (var item in result) {
          if (item?.isNotEmpty ?? false) {
            listSlot.add('$item');
          }
        }
      }
      return listSlot;
    }
    return <String>[];
  }

  @override
  Future<Map<String, dynamic>>? checkBookingAvailability({data}) => null;

  @override
  Future<List<Store>>? getNearbyStores(Prediction prediction,
          {int page = 1, int perPage = 10, int radius = 10, String? name}) =>
      null;

  @override
  Future<Prediction> getPlaceDetail(
      Prediction prediction, String? sessionToken) async {
    try {
      var endpoint = 'https://maps.googleapis.com/maps/api/place/details/json?'
          'place_id=${prediction.placeId}'
          '&fields=geometry&key=${isIos ? kGoogleApiKey.ios : kGoogleApiKey.android}'
          '&sessiontoken=$sessionToken';

      var response = await httpGet(endpoint.toUri()!);
      var result = convert.jsonDecode(response.body);
      var lat = result['result']['geometry']['location']['lat'].toString();
      var long = result['result']['geometry']['location']['lng'].toString();
      prediction.lat = lat;
      prediction.long = long;
    } catch (e) {
      printLog('getPlaceDetail: $e');
    }
    return prediction;
  }

  @override
  Future<List<Prediction>> getAutoCompletePlaces(
      String term, String? sessionToken) async {
    try {
      var endpoint =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$term&key=${isIos ? kGoogleApiKey.ios : kGoogleApiKey.android}'
          '&sessiontoken=$sessionToken';

      var response = await httpGet(endpoint.toUri()!);
      var result = convert.jsonDecode(response.body);
      var list = <Prediction>[];
      for (var item in result['predictions']) {
        list.add(Prediction.fromJson(item));
      }
      return list;
    } catch (e) {
      printLog('getAutoCompletePlaces: $e');
    }
    return [];
  }

  @override
  Future<List<dynamic>>? getLocations() => null;

  @override
  Future<Product?> getProductByPermalink(String productPermalink) async {
    try {
      final response = await httpGet(
          '$domain/wp-json/api/flutter_woo/products/dynamic?url=$productPermalink'
              .toUri()!);

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonParser(body[0]);
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Category?> getProductCategoryByPermalink(
      String productCategoryPermalink) async {
    try {
      final response = await httpGet(
          '$domain/wp-json/api/flutter_woo/product-category/dynamic?url=$productCategoryPermalink'
              .toUri()!);

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Category.fromJson(body[0]);
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Blog?> getBlogByPermalink(String blogPermaLink) async {
    try {
      final response = await httpGet(
          '$domain/wp-json/api/flutter_blog/blog/dynamic?url=$blogPermaLink'
              .toUri()!);
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Blog.fromJson(body);
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<Brand>?> getBrands(
      {int page = 1, int perPage = 10, required String lang}) async {
    try {
      var endpoint =
          'products/brands?per_page=$perPage&page=$page&lang=$lang&hide_empty=true';
      var response = await wcApi.getAsync(endpoint);
      var list = <Brand>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Brand.fromJson(item));
        }
        return list;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<Product>?> fetchProductsByBrand({page, lang, brandId}) async {
    try {
      var endpoint =
          'products?brand=$brandId&page=$page&per_page=10&lang=$lang';
      endpoint = buildUrlToGetProducts(endpoint);
      var response = await wcApi.getAsync(endpoint);
      var list = <Product>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          final product = Product.fromJson(item);
          if ((kAdvanceConfig.hideOutOfStock) && !product.inStock!) {
            /// hideOutOfStock product
            continue;
          }
          list.add(product);
        }
        return list;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<OrderDeliveryDate>> getListDeliveryDates({storeId}) async {
    var list = <OrderDeliveryDate>[];
    try {
      var endpoint = '$domain/wp-json/api/flutter_woo/ddates';
      if (storeId != null) {
        endpoint += '?id=$storeId';
      }
      var response = await httpGet(endpoint.toUri()!);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result) {
          list.add(OrderDeliveryDate.fromJson(item));
        }
      }
    } catch (e, trace) {
      printLog(e);
      printLog(trace);
    }
    return list;
  }

  @override
  Future<bool> isUserExisted({String? phone, String? username}) async {
    try {
      var endpoint = '$domain/wp-json/api/flutter_user/check-user?';
      if (phone != null) {
        final mobile = phone.replaceAll('+', '').replaceAll(' ', '');
        endpoint += '&phone=$mobile';
      }
      if (username != null) {
        endpoint += '&username=$username';
      }
      final response = await httpGet(
        endpoint.toUri()!,
      );
      if (response.statusCode == 200) {
        /// Need to trim. It returns "									true" for some reason 😂.
        return response.body.trim() == 'true';
      }
    } catch (e) {
      printLog('isPhoneNumberExisted $e');
    }
    return false;
  }

  @override
  Future<Category?> getProductCategoryById({required categoryId}) async {
    try {
      var url = 'products/categories/$categoryId';
      var response = await wcApi.getAsync(url);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        return Category.fromJson(response);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Brand?> getBrandById(brandId) async {
    try {
      var url = 'products/brands/$brandId';
      var response = await wcApi.getAsync(url);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        return Brand.fromJson(response);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<Brand?> getBrandBySlug(String slug) async {
    try {
      var url = 'products/brands?slug=$slug';
      var response = await wcApi.getAsync(url);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        final brandItem = List.from(response).firstOrNull;
        if (brandItem == null) throw 'This brand does not exist';
        return Brand.fromJson(brandItem);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(
      {required String? productId, required String? cookie}) async {
    try {
      final response = await httpDelete(
          '$domain/wp-json/api/flutter_multi_vendor/product/$productId'
              .toUri()!,
          headers: {'User-Cookie': cookie!, 'Content-Type': 'application/json'},
          enableDio: true);
      var body = convert.jsonDecode(response.body);
      if (body['message'] == null) {
        return;
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<dynamic>? getDataFromScanner(String data, {String? cookie}) async {
    try {
      var endpoint = '$domain/wp-json/api/flutter_woo/scanner?data=$data';
      if (cookie != null) {
        var base64Str = EncodeUtils.encodeCookie(cookie);
        endpoint += '&token=$base64Str';
      }
      final response = await httpGet(endpoint.toUri()!, enableDio: true);
      var body = convert.jsonDecode(response.body);

      if (body['code'] == null) {
        if (body['type'] == 'product') {
          return Product.fromJson(body['data'].first);
        }
        if (body['type'] == 'shop_order') {
          return Order.fromJson(body['data'].first);
        }
        return null;
      } else {
        throw body['code'];
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Category>> getSubCategories({
    String? langCode,
    int page = 1,
    int limit = 25,
    required String? parentId,
  }) async {
    try {
      var url =
          'products/categories?parent=${parentId ?? _rootCategoryId}&exclude=$kExcludedCategory&per_page=$limit&page=$page&hide_empty=${kAdvanceConfig.hideEmptyCategories}';
      if (langCode != null && kAdvanceConfig.isMultiLanguages) {
        url += '&lang=$langCode';
      }
      var response = await wcApi.getAsync(url);
      return PagingResponse<Category>(
        data: Category.parseCategoryList(response),
      );
    } catch (e) {
      //This error exception is about your RegetHomeCache(st API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<bool> checkProductPermission(String productId, String? cookie) async {
    try {
      var endpoint =
          '$domain/wp-json/api/flutter_woo/products/$productId/check';
      if (cookie != null) {
        var base64Str = EncodeUtils.encodeCookie(cookie);
        endpoint += '?token=$base64Str';
      }
      final response = await httpGet(endpoint.toUri()!, enableDio: true);
      var body = convert.jsonDecode(response.body);

      if (body is Map && isNotBlank(body['message'])) {
        throw body['message'];
      } else {
        return body == true;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteAccount(String token) async {
    try {
      final response = await httpDelete(
          '$domain/wp-json/api/flutter_customer/delete_account'.toUri()!,
          headers: {
            'User-Cookie': token,
            'Content-Type': 'application/json',
          });
      var body = convert.jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        throw body['message'];
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Product>> getProductsByCategoryId(
    String categoryId, {
    String? langCode,
    int page = 1,
    int limit = 25,
  }) async {
    try {
      var url = 'products?category=$categoryId&per_page=$limit&page=$page';
      if (langCode != null && kAdvanceConfig.isMultiLanguages) {
        url += '&lang=$langCode';
      }
      final response = await wcApi.getAsync(url, version: 3);
      var list = <Product>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(jsonParser(item));
        }
        return PagingResponse(data: list);
      }
    } catch (e) {
      return const PagingResponse(data: []);
    }
  }
}
