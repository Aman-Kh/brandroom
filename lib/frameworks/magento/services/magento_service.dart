import 'dart:async';
import 'dart:convert' as convert;

import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/index.dart'
    show
        CartModel,
        Category,
        Coupons,
        Order,
        OrderStatus,
        PaymentMethod,
        Product,
        ProductAttribute,
        ProductVariation,
        Review,
        ShippingMethod,
        Store,
        Tax,
        User,
        UserModel;
import '../../../services/base_services.dart';
import '../../../services/https.dart';
import 'magento_helper.dart';

const bool kEnableProductThumbnail = false;
const emptyShippingMsg =
    'There are no shipping options available. Please ensure that your address has been entered correctly, or contact us if you need any help.';

class MagentoService extends BaseServices {
  final String accessToken;
  String? guestQuoteId;
  Map<String, ProductAttribute>? attributes;

  MagentoService({
    required String domain,
    String? blogDomain,
    required this.accessToken,
  })  : attributes = null,
        guestQuoteId = null,
        super(domain: domain, blogDomain: blogDomain);

  Product parseProductFromJson(item) {
    final dateSaleFrom = MagentoHelper.getCustomAttribute(
        item['custom_attributes'], 'special_from_date');
    final dateSaleTo = MagentoHelper.getCustomAttribute(
        item['custom_attributes'], 'special_to_date');
    var onSale = false;
    var price = item['price'];
    var salePrice = MagentoHelper.getCustomAttribute(
        item['custom_attributes'], 'special_price');
    if (dateSaleFrom != null || dateSaleTo != null) {
      final now = DateTime.now();
      if (dateSaleFrom != null && dateSaleTo != null) {
        onSale = now.isAfter(DateTime.parse(dateSaleFrom)) &&
            now.isBefore(DateTime.parse(dateSaleTo));
      }
      if (dateSaleFrom != null && dateSaleTo == null) {
        onSale = now.isAfter(DateTime.parse(dateSaleFrom));
      }
      if (dateSaleFrom == null && dateSaleTo != null) {
        onSale = now.isBefore(DateTime.parse(dateSaleTo));
      }
      if (onSale && salePrice != null) {
        price = salePrice;
      }
    } else if (salePrice != null &&
        dateSaleFrom == null &&
        dateSaleTo == null) {
      onSale = double.parse("${item["price"]}") > double.parse(salePrice);
      price = salePrice;
    }

    final mediaGalleryEntries = item['media_gallery_entries'];
    var images = kEnableProductThumbnail
        ? [MagentoHelper.getProductImageUrl(domain, item, 'thumbnail')]
        : <String>[];
    if (mediaGalleryEntries != null &&
            (kEnableProductThumbnail && mediaGalleryEntries.length > 1) ||
        (!kEnableProductThumbnail && mediaGalleryEntries.length > 0)) {
      for (var item in mediaGalleryEntries) {
        images
            .add(MagentoHelper.getProductImageUrlByName(domain, item['file']));
      }
    }
    var product = Product.fromMagentoJson(item);
    final description = MagentoHelper.getCustomAttribute(
        item['custom_attributes'], 'description');
    product.description = description ??
        MagentoHelper.getCustomAttribute(
            item['custom_attributes'], 'short_description');
    if (item['type_id'] == 'configurable') {
      if (product.price == null) {
        product.price = MagentoHelper.getCustomAttribute(
            item['custom_attributes'], 'minimal_price');
      } else {
        product.price = '$price';
      }
      product.regularPrice = product.price;
      product.salePrice = product.price;
      product.onSale = false;
    } else {
      product.price = '$price';
      product.regularPrice = "${item["price"]}";
      product.salePrice = onSale ? salePrice : product.price;
      product.onSale = onSale;
    }

    product.images = images;
    product.imageFeature = images.isNotEmpty ? images[0] : null;

    List<dynamic>? categoryIds;
    if (item['custom_attributes'] != null &&
        item['custom_attributes'].length > 0) {
      for (var item in item['custom_attributes']) {
        if (item['attribute_code'] == 'category_ids') {
          categoryIds = item['value'];
          break;
        }
      }
    }
    product.categoryId = categoryIds!.isNotEmpty ? '${categoryIds[0]}' : '0';
    product.permalink = '';

    var attrs = <ProductAttribute>[];
    final options = item['extension_attributes'] != null &&
            item['extension_attributes']['configurable_product_options'] != null
        ? item['extension_attributes']['configurable_product_options']
        : [];

    List? attrsList = kAdvanceConfig.enableAttributesConfigurableProduct;
    List? attrsLabelList =
        kAdvanceConfig.enableAttributesLabelConfigurableProduct;
    for (var i = 0; i < options.length; i++) {
      final option = options[i];

      for (var j = 0; j < attrsList.length; j++) {
        final item = attrsList[j];
        final itemLabel = attrsLabelList[j];
        if (option['label'].toLowerCase() ==
            itemLabel.toString().toLowerCase()) {
          List? values = option['values'];
          var optionAttr = [];
          if (attributes?[item] != null) {
            for (var f in attributes![item]!.options!) {
              final value = values!.firstWhere(
                  (o) => o['value_index'].toString() == f['value'],
                  orElse: () => null);
              if (value != null) {
                optionAttr.add(f);
              }
            }
            attrs.add(ProductAttribute.fromMagentoJson({
              'attribute_id': attributes![item]!.id,
              'attribute_code': attributes![item]!.name,
              'options': optionAttr
            }));
          }
        }
      }
    }

    product.attributes = attrs;
    product.type = item['type_id'];
    return product;
  }

  Future<bool> getStockStatus(sku) async {
    try {
      var response = await httpGet(
          MagentoHelper.buildUrl(domain, 'stockItems/$sku')!,
          headers: {'Authorization': 'Bearer $accessToken'});

      final body = convert.jsonDecode(response.body);
      return body['is_in_stock'] ?? false;
    } catch (e) {
      rethrow;
    }
  }

  Future getAllAttributes() async {
    try {
      attributes = <String, ProductAttribute>{};
      List attrs = kAdvanceConfig.enableAttributesConfigurableProduct;

      for (var item in attrs) {
        var attrsItem = await getProductAttributes(item);
        attributes![item] = attrsItem;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductAttribute> getProductAttributes(String attributeCode) async {
    try {
      var response = await httpGet(
          MagentoHelper.buildUrl(domain, 'products/attributes/$attributeCode')!,
          headers: {'Authorization': 'Bearer $accessToken'});

      final body = convert.jsonDecode(response.body);
      if (body['message'] != null) {
        throw Exception(MagentoHelper.getErrorMessage(body));
      } else {
        return ProductAttribute.fromMagentoJson(body);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategories({lang}) async {
    try {
      var response = await httpGet(
          MagentoHelper.buildUrl(domain, 'mstore/categories', lang)!,
          headers: {'Authorization': 'Bearer $accessToken'});
      var list = <Category>[];
      if (response.statusCode == 200) {
        for (var item in convert.jsonDecode(response.body)['children_data']) {
          if (item['is_active'] == true) {
            var category = Category.fromMagentoJson(item);
            category.parent = '0';
            if (item['image'] != null) {
              category.image = item['image'].toString().contains('media/')
                  ? "$domain/${item["image"]}"
                  : "$domain/pub/media/catalog/category/${item["image"]}";
            }
            list.add(category);

            for (var item1 in item['children_data']) {
              if (item1['is_active'] == true) {
                list.add(Category.fromMagentoJson(item1));

                for (var item2 in item1['children_data']) {
                  if (item1['is_active'] == true) {
                    list.add(Category.fromMagentoJson(item2));
                  }
                }
              }
            }
          }
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts({userId}) async {
    try {
      var response = await httpGet(
          MagentoHelper.buildUrl(
              domain, 'mstore/products&searchCriteria[pageSize]=$apiPageSize')!,
          headers: {'Authorization': 'Bearer $accessToken'});
      var list = <Product>[];
      if (response.statusCode == 200) {
        for (var item in convert.jsonDecode(response.body)['items']) {
          var product = parseProductFromJson(item);
          list.add(product);
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>> fetchProductsLayout(
      {required config, lang, userId, bool refreshCache = false}) async {
    try {
      var list = <Product>[];
      if (config['layout'] == 'imageBanner' ||
          config['layout'] == 'circleCategory') {
        return list;
      }

      var endPoint = '?';
      if (config.containsKey('category')) {
        endPoint +=
            "searchCriteria[filter_groups][0][filters][0][field]=category_id&searchCriteria[filter_groups][0][filters][0][value]=${config["category"]}&searchCriteria[filter_groups][0][filters][0][condition_type]=eq&searchCriteria[pageSize]=${config['limit'] ?? apiPageSize}";
      }
      if (config.containsKey('page')) {
        endPoint += "&searchCriteria[currentPage]=${config["page"]}";
      }
      endPoint +=
          '&searchCriteria[filter_groups][1][filters][0][field]=visibility&searchCriteria[filter_groups][1][filters][0][value]=4';

      var response = await httpCache(
        MagentoHelper.buildUrl(domain, 'mstore/products$endPoint', lang)!,
        headers: {'Authorization': 'Bearer $accessToken'},
        refreshCache: refreshCache,
      );

      if (response.statusCode == 200) {
        for (var item in convert.jsonDecode(response.body)['items']) {
          var product = parseProductFromJson(item);
          list.add(product);
        }
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
      page,
      minPrice,
      maxPrice,
      lang,
      orderBy,
      order,
      featured,
      onSale,
      attribute,
      attributeTerm,
      listingLocation,
      userId,
      String? include,
      String? search,
      nextCursor}) async {
    try {
      var endPoint = '?';
      if (categoryId != null) {
        endPoint +=
            'searchCriteria[filter_groups][0][filters][0][field]=category_id&searchCriteria[filter_groups][0][filters][0][value]=$categoryId&searchCriteria[filter_groups][0][filters][0][condition_type]=eq';
      }
      if (minPrice != null) {
        endPoint +=
            '&searchCriteria[filter_groups][0][filters][1][field]=price&searchCriteria[filter_groups][0][filters][1][value]=$minPrice&searchCriteria[filter_groups][0][filters][1][condition_type]=gteq';
      }
      if (maxPrice != null) {
        endPoint +=
            '&searchCriteria[filter_groups][2][filters][1][field]=price&searchCriteria[filter_groups][2][filters][1][value]=$maxPrice&searchCriteria[filter_groups][2][filters][1][condition_type]=lteq';
      }

      if (search != null) {
        endPoint +=
            'searchCriteria[filter_groups][0][filters][0][field]=name&searchCriteria[filter_groups][0][filters][0][value]=%$search%&searchCriteria[filter_groups][0][filters][0][condition_type]=like';
      }

      if (page != null) {
        endPoint += '&searchCriteria[currentPage]=$page';
      }
      if (orderBy != null) {
        endPoint +=
            "&searchCriteria[sortOrders][1][field]=${orderBy == "date" ? "created_at" : orderBy}";
      } else {
        endPoint += '&searchCriteria[sortOrders][1][field]=created_at';
      }
      if (order != null) {
        endPoint +=
            '&searchCriteria[sortOrders][1][direction]=${(order as String).toUpperCase()}';
      } else {
        endPoint += '&searchCriteria[sortOrders][1][direction]=DESC';
      }
      if (onSale == true) {
        endPoint +=
            '&searchCriteria[filter_groups][3][filters][0][field]=special_price&searchCriteria[filter_groups][3][filters][0][condition_type]=notnull';
      }
      endPoint += '&searchCriteria[pageSize]=$apiPageSize';

      endPoint +=
          '&searchCriteria[filter_groups][1][filters][0][field]=visibility&searchCriteria[filter_groups][1][filters][0][value]=4';

      var response = await httpGet(
          MagentoHelper.buildUrl(domain, 'mstore/products$endPoint', lang)!,
          headers: {'Authorization': 'Bearer $accessToken'});

      var list = <Product>[];
      if (response.statusCode == 200) {
        for (var item in convert.jsonDecode(response.body)['items']) {
          var product = parseProductFromJson(item);
          list.add(product);
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> loginFacebook({String? token}) async {
    try {
      var response = await httpPost(
          MagentoHelper.buildUrl(domain, 'mstore/social_login')!,
          body: convert.jsonEncode({'token': token, 'type': 'facebook'}),
          headers: {'content-type': 'application/json'});

      if (response.statusCode == 200) {
        final token = convert.jsonDecode(response.body);
        var user = await getUserInfo(token);
        user.isSocial = true;
        return user;
      } else {
        final body = convert.jsonDecode(response.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get token');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<User> loginSMS({String? token}) async {
    try {
      var response = await httpPost(
        MagentoHelper.buildUrl(domain, 'mstore/social_login')!,
        body: convert.jsonEncode({'token': token, 'type': 'firebase_sms'}),
        headers: {'content-type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final token = convert.jsonDecode(response.body);
        var user = await getUserInfo(token);
        user.isSocial = true;
        return user;
      } else {
        final body = convert.jsonDecode(response.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get token');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<List<Review>>? getReviews(productId,
      {int page = 1, int perPage = 10}) {
    return null;
  }

  @override
  Future<List<ProductVariation>> getProductVariations(Product product,
      {String? lang = 'en'}) async {
    try {
      final res = await httpGet(
          MagentoHelper.buildUrl(
              domain, 'configurable-products/${product.sku}/children')!,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'content-type': 'application/json'
          });

      var list = <ProductVariation>[];
      if (res.statusCode == 200) {
        for (var item in convert.jsonDecode(res.body)) {
          var prod = ProductVariation.fromMagentoJson(item, product);
          prod.inStock = await getStockStatus(prod.sku);
          list.add(prod);
        }
      }

      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ShippingMethod>> getShippingMethods(
      {CartModel? cartModel,
      String? token,
      String? checkoutId,
      Store? store,
      String? langCode}) async {
    try {
      var address = cartModel!.address!;
      var url = token != null
          ? MagentoHelper.buildUrl(
              domain, 'carts/mine/estimate-shipping-methods')!
          : MagentoHelper.buildUrl(
              domain, 'guest-carts/$guestQuoteId/estimate-shipping-methods')!;
      final res = await httpPost(url,
          body: convert.jsonEncode(address.toMagentoJson()),
          headers: token != null
              ? {
                  'Authorization': 'Bearer $token',
                  'content-type': 'application/json'
                }
              : {'content-type': 'application/json'});

      if (res.statusCode == 200) {
        var list = <ShippingMethod>[];
        for (var item in convert.jsonDecode(res.body)) {
          list.add(ShippingMethod.fromMagentoJson(item));
        }
        if (list.isEmpty) {
          throw Exception(emptyShippingMsg);
        }
        return list;
      } else {
        final body = convert.jsonDecode(res.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get shipping methods');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods(
      {CartModel? cartModel,
      ShippingMethod? shippingMethod,
      String? token,
      String? langCode}) async {
    try {
      var address = cartModel!.address;
      final params = {
        'addressInformation': {
          'shipping_address': address?.toMagentoJson()['address'],
          'billing_address': address?.toMagentoJson()['address'],
          'shipping_carrier_code': shippingMethod?.id,
          'shipping_method_code': shippingMethod?.methodId
        }
      };
      var url = token != null
          ? MagentoHelper.buildUrl(domain, 'carts/mine/shipping-information')!
          : MagentoHelper.buildUrl(
              domain, 'guest-carts/$guestQuoteId/shipping-information')!;
      final res = await httpPost(url,
          body: convert.jsonEncode(params),
          headers: token != null
              ? {
                  'Authorization': 'Bearer $token',
                  'content-type': 'application/json'
                }
              : {'content-type': 'application/json'});

      final body = convert.jsonDecode(res.body);
      if (res.statusCode == 200) {
        var list = <PaymentMethod>[];
        for (var item in body['payment_methods']) {
          if (!item['code'].toString().contains('fake')) {
            list.add(PaymentMethod.fromMagentoJson(item));
          }
        }
        return list;
      } else if (body['message'] != null) {
        throw Exception(MagentoHelper.getErrorMessage(body));
      } else {
        throw Exception('Can not get payment methods');
      }
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
      var endPoint = '?';
      endPoint +=
          'searchCriteria[filter_groups][0][filters][0][field]=customer_email&searchCriteria[filter_groups][0][filters][0][value]=${user!.email}&searchCriteria[filter_groups][0][filters][0][condition_type]=eq';
      endPoint += '&searchCriteria[currentPage]=${cursor - 1}';
      endPoint += '&searchCriteria[sortOrders][1][field]=created_at';
      endPoint += '&searchCriteria[pageSize]=$apiPageSize';
      endPoint += '&dummy=${DateTime.now().millisecondsSinceEpoch}';

      var response = await httpGet(
          MagentoHelper.buildUrl(domain, 'orders$endPoint')!,
          headers: {'Authorization': 'Bearer $accessToken'});

      var list = <Order>[];
      if (response.statusCode == 200) {
        for (var item in convert.jsonDecode(response.body)['items']) {
          list.add(Order.fromJson(item));
        }
      }
      return PagingResponse(data: list);
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<Order> createOrder({
    CartModel? cartModel,
    UserModel? user,
    bool? paid,
    String? transactionId,
  }) async {
    try {
      var isGuest = user!.user == null || user.user!.cookie == null;
      var url = !isGuest
          ? MagentoHelper.buildUrl(domain, 'carts/mine/payment-information')!
          : MagentoHelper.buildUrl(
              domain, 'guest-carts/$guestQuoteId/payment-information')!;
      var params = Order().toMagentoJson(cartModel!, null, paid);
      if (isGuest) {
        params['email'] = cartModel.address!.email;
        params['firstname'] = cartModel.address!.firstName;
        params['lastname'] = cartModel.address!.lastName;
      }
      if (transactionId != null && transactionId.isNotEmpty) {
        params['paymentMethod'] = {
          'method': params['paymentMethod']['method'],
          'additional_data': {'rzp_payment_id': transactionId}
        };
      }

      final res = await httpPost(url,
          body: convert.jsonEncode(params),
          headers: !isGuest
              ? {
                  'Authorization': 'Bearer ${user.user!.cookie!}',
                  'content-type': 'application/json'
                }
              : {'content-type': 'application/json'});

      final body = convert.jsonDecode(res.body);
      if (res.statusCode == 200) {
        var order = Order();
        order.id = body.toString();
        order.number = body.toString();
        order.status = OrderStatus.pending;
        return order;
      } else {
        if (body['message'] != null) {
          throw Exception(MagentoHelper.getErrorMessage(body));
        } else {
          throw Exception('Can not create order');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future updateOrder(orderId, {status, required token}) async {
    try {
      var response = await httpPost(
        MagentoHelper.buildUrl(domain, 'mstore/me/orders/$orderId/cancel')!,
        body: convert.jsonEncode({}),
        headers: {
          'Authorization': 'Bearer $token',
          'content-type': 'application/json'
        },
      );
      final body = convert.jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        throw Exception(MagentoHelper.getErrorMessage(body));
      } else {
        return;
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<Order?> cancelOrder({
    Order? order,
    String? userCookie,
  }) async {
    await updateOrder(order!.id, status: 'cancelled', token: userCookie);
    order.status = OrderStatus.cancelled;
    return order;
  }

  @override
  Future<PagingResponse<Product>> searchProducts(
      {name,
      categoryId,
      categoryName,
      tag,
      attribute,
      attributeId,
      page,
      lang,
      listingLocation,
      userId}) async {
    try {
      var endPoint = '?';
      if (name != null) {
        endPoint +=
            'searchCriteria[filter_groups][0][filters][0][field]=name&searchCriteria[filter_groups][0][filters][0][value]=%$name%&searchCriteria[filter_groups][0][filters][0][condition_type]=like';
      }
      if (page != null) {
        endPoint += '&searchCriteria[currentPage]=$page';
      }
      endPoint += '&searchCriteria[pageSize]=$apiPageSize';
      endPoint +=
          '&searchCriteria[filter_groups][1][filters][0][field]=visibility&searchCriteria[filter_groups][1][filters][0][value]=4';

      var response = await httpGet(
          MagentoHelper.buildUrl(domain, 'mstore/products$endPoint')!,
          headers: {'Authorization': 'Bearer $accessToken'});

      var list = <Product>[];
      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body);
        if (!MagentoHelper.isEndLoadMore(body)) {
          for (var item in body['items']) {
            var product = parseProductFromJson(item);
            list.add(product);
          }
        }
      }
      return PagingResponse(data: list);
    } catch (err, trace) {
      printLog(trace);
      rethrow;
    }
  }

  @override
  Future<User> createUser({
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    String? phoneNumber,
    bool isVendor = false,
  }) async {
    try {
      var response =
          await httpPost(MagentoHelper.buildUrl(domain, 'customers')!,
              body: convert.jsonEncode({
                'customer': {
                  'email': username,
                  'firstname': firstName,
                  'lastname': lastName
                },
                'password': password
              }),
              headers: {'content-type': 'application/json'});

      if (response.statusCode == 200) {
        return await login(username: username, password: password);
      } else {
        final body = convert.jsonDecode(response.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get token');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<User> getUserInfo(cookie) async {
    try {
      var res = await httpGet(MagentoHelper.buildUrl(domain, 'customers/me')!,
          headers: {'Authorization': 'Bearer $cookie'});
      final body = convert.jsonDecode(res.body);
      if (body['message'] != null) {
        throw Exception(MagentoHelper.getErrorMessage(body));
      } else {
        return User.fromMagentoJson(body, cookie);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> login({username, password}) async {
    try {
      var response = await httpPost(
          MagentoHelper.buildUrl(domain, 'integration/customer/token')!,
          body:
              convert.jsonEncode({'username': username, 'password': password}),
          headers: {'content-type': 'application/json'});

      if (response.statusCode == 200) {
        final token = convert.jsonDecode(response.body);
        var user = await getUserInfo(token);
        return user;
      } else {
        final body = convert.jsonDecode(response.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get token');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<User> loginApple({String? token}) async {
    try {
      var response = await httpPost(
          MagentoHelper.buildUrl(domain, 'mstore/social_login')!,
          body: convert.jsonEncode({'token': token, 'type': 'apple'}),
          headers: {'content-type': 'application/json'});

      if (response.statusCode == 200) {
        final token = convert.jsonDecode(response.body);
        var user = await getUserInfo(token);
        user.isSocial = true;
        return user;
      } else {
        final body = convert.jsonDecode(response.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get token');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<Product?> getProduct(id, {lang}) async {
    var endPoint =
        '?searchCriteria[filterGroups][0][filters][0][field]=entity_id&searchCriteria[filterGroups][0][filters][0][condition_type]=eq';
    endPoint += '&searchCriteria[filterGroups][0][filters][0][value]=$id';
    var response = await httpGet(
        MagentoHelper.buildUrl(domain, 'products$endPoint')!,
        headers: {'Authorization': 'Bearer $accessToken'});
    var products = convert.jsonDecode(response.body)['items'];
    if (products.isEmpty) return null;
    return parseProductFromJson(products[0]);
  }

  Future<bool> deleteItemsInCart(List<Map> items, String? token) async {
    try {
      await Future.forEach(items, (Map item) async {
        await httpDelete(
            MagentoHelper.buildUrl(
                domain, 'carts/mine/items/${item['item_id']}')!,
            headers: {'Authorization': 'Bearer $token'});
      });
      await httpDelete(MagentoHelper.buildUrl(domain, 'carts/mine/coupons')!,
          headers: {'Authorization': 'Bearer $token'});
      return true;
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> addToCart(CartModel cartModel, String? token, quoteId,
      {guestCartId}) async {
    try {
      //add items to cart
      await Future.forEach(cartModel.productsInCart.keys, (dynamic key) async {
        var params = <String, dynamic>{};
        params['qty'] = cartModel.productsInCart[key];
        params['quote_id'] = quoteId;
        params['sku'] = cartModel.productSkuInCart[key];
        final res = await httpPost(
            guestCartId == null
                ? MagentoHelper.buildUrl(domain, 'carts/mine/items')!
                : MagentoHelper.buildUrl(domain, 'guest-carts/$quoteId/items')!,
            body: convert.jsonEncode({'cartItem': params}),
            headers: token != null
                ? {
                    'Authorization': 'Bearer $token',
                    'content-type': 'application/json'
                  }
                : {'content-type': 'application/json'});
        final body = convert.jsonDecode(res.body);
        if (body['messages'] != null &&
            body['messages']['error'] != null &&
            body['messages']['error'][0].length > 0) {
          throw MagentoHelper.getErrorMessage(body['messages']['error'][0])!;
        } else if (body['message'] != null) {
          throw MagentoHelper.getErrorMessage(body)!;
        } else {
          printLog(body);
          return;
        }
      });
      return true;
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> addItemsToCart(CartModel cartModel, String? token) async {
    try {
      if (token != null) {
        //get cart info
        var res = await httpGet(MagentoHelper.buildUrl(domain, 'carts/mine')!,
            headers: {'Authorization': 'Bearer $token'});
        final cartInfo = convert.jsonDecode(res.body);
        if (res.statusCode == 200) {
          if (cartInfo['items'] is List) {
            await deleteItemsInCart(List<Map>.from(cartInfo['items']), token);
          }
          return await addToCart(cartModel, token, cartInfo['id']);
        } else if (res.statusCode == 401) {
          throw Exception('Token expired. Please logout then login again');
        } else if (res.statusCode != 404) {
          throw Exception(MagentoHelper.getErrorMessage(cartInfo));
        }
      }

      //create a quote
      var url = token != null
          ? MagentoHelper.buildUrl(domain, 'carts/mine')!
          : MagentoHelper.buildUrl(domain, 'guest-carts')!;
      var res = await httpPost(url,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {});
      if (res.statusCode == 200) {
        if (token != null) {
          final quoteId = convert.jsonDecode(res.body);
          return await addToCart(cartModel, token, quoteId);
        } else {
          String? quoteId = convert.jsonDecode(res.body);
          var response = await httpGet(
              MagentoHelper.buildUrl(domain, 'guest-carts/$quoteId')!);
          final cartInfo = convert.jsonDecode(response.body);
          if (response.statusCode == 200) {
            final cartId = cartInfo['id'];
            guestQuoteId = quoteId;
            return await addToCart(cartModel, token, quoteId,
                guestCartId: cartId);
          } else {
            throw Exception(MagentoHelper.getErrorMessage(cartInfo));
          }
        }
      } else {
        throw Exception(
            MagentoHelper.getErrorMessage(convert.jsonDecode(res.body)));
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<double> applyCoupon(String? token, String? coupon) async {
    try {
      var url = token != null
          ? MagentoHelper.buildUrl(domain, 'carts/mine/coupons/$coupon')!
          : MagentoHelper.buildUrl(
              domain, 'guest-carts/$guestQuoteId/coupons/$coupon')!;
      var res = await httpPut(url,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {});
      var body = convert.jsonDecode(res.body);
      if (res.statusCode == 200) {
        var totalUrl = token != null
            ? MagentoHelper.buildUrl(domain, 'carts/mine/totals')!
            : MagentoHelper.buildUrl(
                domain, 'guest-carts/$guestQuoteId/totals')!;
        var res = await httpGet(totalUrl,
            headers: token != null ? {'Authorization': 'Bearer $token'} : {});
        body = convert.jsonDecode(res.body);
        if (body['message'] != null) {
          throw Exception(MagentoHelper.getErrorMessage(body));
        } else {
          var discount = double.parse("${body['discount_amount']}");
          return discount < 0 ? discount * (-1) : discount;
        }
      } else {
        throw Exception(MagentoHelper.getErrorMessage(body));
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<Coupons> getCoupons({int page = 1, String search = ''}) async {
    try {
      return Coupons.getListCoupons([]);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> loginGoogle({String? token}) async {
    try {
      var response = await httpPost(
          MagentoHelper.buildUrl(domain, 'mstore/social_login')!,
          body: convert.jsonEncode({'token': token, 'type': 'google'}),
          headers: {'content-type': 'application/json'});

      if (response.statusCode == 200) {
        final token = convert.jsonDecode(response.body);
        var user = await getUserInfo(token);
        user.isSocial = true;
        return user;
      } else {
        final body = convert.jsonDecode(response.body);
        throw Exception(body['message'] != null
            ? MagentoHelper.getErrorMessage(body)
            : 'Can not get token');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserInfo(
      Map<String, dynamic> json, String? token) async {
    try {
      if (isNotBlank(json['user_email'])) {
        var response = await httpPost(
          MagentoHelper.buildUrl(domain, 'mstore/customers/me/changeEmail')!,
          body: convert.jsonEncode({
            'new_email': json['user_email'],
            'current_password': json['current_pass']
          }),
          headers: {
            'Authorization': 'Bearer ${token!}',
            'content-type': 'application/json'
          },
        );
        final body = convert.jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          throw Exception(MagentoHelper.getErrorMessage(body));
        }
      }
      if (isNotBlank(json['user_pass'])) {
        var response = await httpPost(
          MagentoHelper.buildUrl(domain, 'mstore/customers/me/changePassword')!,
          body: convert.jsonEncode({
            'new_password': json['user_pass'],
            'confirm_password': json['user_pass'],
            'current_password': json['current_pass']
          }),
          headers: {
            'Authorization': 'Bearer ${token!}',
            'content-type': 'application/json'
          },
        );
        final body = convert.jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          throw Exception(MagentoHelper.getErrorMessage(body));
        }
      }
      return json;
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future getCountries() async {
    var response =
        await httpGet(MagentoHelper.buildUrl(domain, 'directory/countries')!);
    final body = convert.jsonDecode(response.body);
    return body;
  }

  Future<bool?> resetPassword(String email) async {
    try {
      var response = await httpPut(
        MagentoHelper.buildUrl(domain, 'customers/password')!,
        body: convert.jsonEncode({'email': email, 'template': 'email_reset'}),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'content-type': 'application/json'
        },
      );

      return convert.jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  // @override
  // Future<PagingResponse<Blog>> getBlogs(dynamic cursor) async {
  //   try {
  //     final param = '_embed&page=$cursor';
  //     // if (categories != null) {
  //     //   param += '&categories=$categories';
  //     // }
  //     final response =
  //         await httpGet('${blogApi!.url}/wp-json/wp/v2/posts?$param'.toUri()!);
  //
  //     if (response.statusCode != 200) {
  //       return const PagingResponse();
  //     }
  //
  //     List data = convert.jsonDecode(response.body);
  //
  //     return PagingResponse(data: data.map((e) => Blog.fromJson(e)).toList());
  //   } on Exception catch (_) {
  //     return const PagingResponse();
  //   }
  // }

  @override
  Future<String?> createPaymentIntentStripe(
      {required String totalPrice,
      String? currencyCode,
      String? emailAddress,
      String? name,
      required String paymentMethodId}) async {
    try {
      var response = await httpPost(
        MagentoHelper.buildUrl(domain, 'mstore/stripe/payment-intent')!,
        body: convert.jsonEncode({
          'payment_method_id': paymentMethodId,
          'email': emailAddress,
          'amount': totalPrice,
          'currencyCode': currencyCode,
          'captureMethod': (kStripeConfig['enableManualCapture'] ?? false)
              ? 'manual'
              : 'automatic'
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'content-type': 'application/json'
        },
      );

      var body = convert.jsonDecode(response.body);
      body = body is List && body.isNotEmpty ? body[0] : body;
      if (body['client_secret'] != null) {
        return body['client_secret'];
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getTaxes(CartModel cartModel) async {
    try {
      var response = await httpGet(
        MagentoHelper.buildUrl(domain, 'taxRates/search?searchCriteria')!,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'content-type': 'application/json'
        },
      );

      var body = convert.jsonDecode(response.body);
      if (body is Map && body['items'] != null && body['items'] is List) {
        var taxes = <Tax>[];
        final address = cartModel.address?.toMagentoJson()['address'];
        body['items'].forEach((item) {
          if ((item['tax_country_id'] == '*' ||
                  item['tax_country_id'] == address['country_id']) &&
              (item['tax_region_id'] == 0 ||
                  item['tax_region_id'] == address['region_id']) &&
              (item['tax_postcode'] == '*' ||
                  item['tax_postcode'] == address['postcode'])) {
            taxes.add(Tax.fromMagentoJson(item, cartModel.getSubTotal() ?? 0));
          }
        });
        taxes = taxes.where((e) => e.amount != null && e.amount! > 0).toList();
        return {
          'items': taxes,
          'total': '${taxes.isNotEmpty ? taxes[0].amount : 0}'
        };
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }
}
