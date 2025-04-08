class DeliveryInfoModel {
  int? _id;
  String? _name;
  int? _status;
  DeliveryChargeSetup? _deliveryChargeSetup;
  List<DeliveryChargeByArea>? _deliveryChargeByArea;

  DeliveryInfoModel(
      {int? id,
        String? name,
        int? status,
        DeliveryChargeSetup? deliveryChargeSetup,
        List<DeliveryChargeByArea>? deliveryChargeByArea}) {
    if (id != null) {
      _id = id;
    }
    if (name != null) {
      _name = name;
    }
    if (status != null) {
      _status = status;
    }
    if (deliveryChargeSetup != null) {
      _deliveryChargeSetup = deliveryChargeSetup;
    }
    if (deliveryChargeByArea != null) {
      _deliveryChargeByArea = deliveryChargeByArea;
    }
  }

  int? get id => _id;
  set id(int? id) => _id = id;
  String? get name => _name;
  set name(String? name) => _name = name;
  int? get status => _status;
  set status(int? status) => _status = status;
  DeliveryChargeSetup? get deliveryChargeSetup => _deliveryChargeSetup;
  set deliveryChargeSetup(DeliveryChargeSetup? deliveryChargeSetup) =>
      _deliveryChargeSetup = deliveryChargeSetup;
  List<DeliveryChargeByArea>? get deliveryChargeByArea => _deliveryChargeByArea;
  set deliveryChargeByArea(List<DeliveryChargeByArea>? deliveryChargeByArea) =>
      _deliveryChargeByArea = deliveryChargeByArea;

  DeliveryInfoModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _status = json['status'];
    _deliveryChargeSetup = json['delivery_charge_setup'] != null
        ? DeliveryChargeSetup.fromJson(json['delivery_charge_setup'])
        : null;
    if (json['delivery_charge_by_area'] != null) {
      _deliveryChargeByArea = <DeliveryChargeByArea>[];
      json['delivery_charge_by_area'].forEach((v) {
        _deliveryChargeByArea!.add(DeliveryChargeByArea.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['name'] = _name;
    data['status'] = _status;
    if (_deliveryChargeSetup != null) {
      data['delivery_charge_setup'] = _deliveryChargeSetup!.toJson();
    }
    if (_deliveryChargeByArea != null) {
      data['delivery_charge_by_area'] =
          _deliveryChargeByArea!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DeliveryChargeSetup {
  int? _id;
  int? _branchId;
  String? _deliveryChargeType;
  double? _deliveryChargePerKilometer;
  double? _minimumDeliveryCharge;
  double? _minimumDistanceForFreeDelivery;
  String? _createdAt;
  String? _updatedAt;
  double? _fixedDeliveryCharge;

  DeliveryChargeSetup(
      {int? id,
        int? branchId,
        String? deliveryChargeType,
        double? deliveryChargePerKilometer,
        double? minimumDeliveryCharge,
        double? minimumDistanceForFreeDelivery,
        String? createdAt,
        String? updatedAt,
        double? fixedDeliveryCharge,
      }) {
    if (id != null) {
      _id = id;
    }
    if (branchId != null) {
      _branchId = branchId;
    }
    if (deliveryChargeType != null) {
      _deliveryChargeType = deliveryChargeType;
    }
    if (deliveryChargePerKilometer != null) {
      _deliveryChargePerKilometer = deliveryChargePerKilometer;
    }
    if (minimumDeliveryCharge != null) {
      _minimumDeliveryCharge = minimumDeliveryCharge;
    }
    if (minimumDistanceForFreeDelivery != null) {
      _minimumDistanceForFreeDelivery = minimumDistanceForFreeDelivery;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    if (fixedDeliveryCharge != null) {
      _fixedDeliveryCharge = fixedDeliveryCharge;
    }
  }

  int? get id => _id;
  set id(int? id) => _id = id;
  int? get branchId => _branchId;
  set branchId(int? branchId) => _branchId = branchId;
  String? get deliveryChargeType => _deliveryChargeType;
  set deliveryChargeType(String? deliveryChargeType) =>
      _deliveryChargeType = deliveryChargeType;
  double? get deliveryChargePerKilometer => _deliveryChargePerKilometer;
  set deliveryChargePerKilometer(double? deliveryChargePerKilometer) =>
      _deliveryChargePerKilometer = deliveryChargePerKilometer;
  double? get minimumDeliveryCharge => _minimumDeliveryCharge;
  set minimumDeliveryCharge(double? minimumDeliveryCharge) =>
      _minimumDeliveryCharge = minimumDeliveryCharge;
  double? get fixedDeliveryCharge => _fixedDeliveryCharge;
  set fixedDeliveryCharge(double? fixedDeliveryCharge) =>
      _fixedDeliveryCharge = fixedDeliveryCharge;
  double? get minimumDistanceForFreeDelivery => _minimumDistanceForFreeDelivery;
  set minimumDistanceForFreeDelivery(double? minimumDistanceForFreeDelivery) =>
      _minimumDistanceForFreeDelivery = minimumDistanceForFreeDelivery;
  String? get createdAt => _createdAt;
  set createdAt(String? createdAt) => _createdAt = createdAt;
  String? get updatedAt => _updatedAt;
  set updatedAt(String? updatedAt) => _updatedAt = updatedAt;


  DeliveryChargeSetup.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _branchId = json['branch_id'];
    _deliveryChargeType = json['delivery_charge_type'];
    _deliveryChargePerKilometer = double.tryParse('${json['delivery_charge_per_kilometer']}');
    _minimumDeliveryCharge = double.tryParse('${json['minimum_delivery_charge']}');
    _minimumDistanceForFreeDelivery = double.tryParse('${json['minimum_distance_for_free_delivery']}');
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _fixedDeliveryCharge = double.tryParse('${json['fixed_delivery_charge']}');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['branch_id'] = _branchId;
    data['delivery_charge_type'] = _deliveryChargeType;
    data['delivery_charge_per_kilometer'] = _deliveryChargePerKilometer;
    data['minimum_delivery_charge'] = _minimumDeliveryCharge;
    data['minimum_distance_for_free_delivery'] =
        _minimumDistanceForFreeDelivery;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    data['fixedDeliveryCharge'] = _fixedDeliveryCharge;
    return data;
  }
}

class DeliveryChargeByArea {
  int? _id;
  int? _branchId;
  String? _areaName;
  int? _deliveryCharge;
  String? _createdAt;
  String? _updatedAt;

  DeliveryChargeByArea(
      {int? id,
        int? branchId,
        String? areaName,
        int? deliveryCharge,
        String? createdAt,
        String? updatedAt}) {
    if (id != null) {
      _id = id;
    }
    if (branchId != null) {
      _branchId = branchId;
    }
    if (areaName != null) {
      _areaName = areaName;
    }
    if (deliveryCharge != null) {
      _deliveryCharge = deliveryCharge;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
  }

  int? get id => _id;
  set id(int? id) => _id = id;
  int? get branchId => _branchId;
  set branchId(int? branchId) => _branchId = branchId;
  String? get areaName => _areaName;
  set areaName(String? areaName) => _areaName = areaName;
  int? get deliveryCharge => _deliveryCharge;
  set deliveryCharge(int? deliveryCharge) => _deliveryCharge = deliveryCharge;
  String? get createdAt => _createdAt;
  set createdAt(String? createdAt) => _createdAt = createdAt;
  String? get updatedAt => _updatedAt;
  set updatedAt(String? updatedAt) => _updatedAt = updatedAt;

  DeliveryChargeByArea.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _branchId = json['branch_id'];
    _areaName = json['area_name'];
    _deliveryCharge = json['delivery_charge'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['branch_id'] = _branchId;
    data['area_name'] = _areaName;
    data['delivery_charge'] = _deliveryCharge;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    return data;
  }
}