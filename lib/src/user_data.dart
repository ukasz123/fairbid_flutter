part of 'internal.dart';

/// Container for information about user. May be used for better targeting ads.
///
/// This data is **not** persistent across application restarts.
class UserData {
  /// Returns current user data.
  static Future<UserData> getCurrent() async {
    if (_instance != null) {
      return _instance!;
    } else {
      Map<String, dynamic> currentData =
          (await FairBidInternal._channel.invokeMapMethod("getUserData"))!.cast();
      _instance = UserData._fromMap(currentData);
      return _instance!;
    }
  }

  final Map<String, dynamic> _userData;

  /// User's gender.
  Gender get gender {
    switch (_userData['gender']) {
      case "m":
        return Gender.male;
      case "f":
        return Gender.female;
      case "o":
        return Gender.other;
      default:
        return Gender.unknown;
    }
  }

  set gender(Gender gender) {
    var code = "u";
    switch (gender) {
      case Gender.other:
        code = "o";
        break;
      case Gender.male:
        code = "m";
        break;
      case Gender.female:
        code = "f";
        break;
      default:
        code = "u";
    }
    _userData["gender"] = code;
    _updateInstance(_userData);
  }

  DateTime? get birthday {
    if (_userData.containsKey('birthday')) {
      var birthdayMap = _userData['birthday'] as Map<String, int>;
      return DateTime(
          birthdayMap['year']!, birthdayMap['month']!, birthdayMap['day']!);
    }
    return null;
  }

  set birthday(DateTime? date) {
    if (date != null) {
      var birthdayMap = <String, int>{
        'year': date.year,
        'month': date.month,
        'day': date.day,
      };
      _userData['birthday'] = birthdayMap;
    } else {
      _userData.remove('birthday');
    }
    _updateInstance(_userData);
  }

  Location? get location {
    if (_userData.containsKey('location')) {
      var locationData = _userData['location'] as Map<String, double>;
      return Location(locationData['latitude'], locationData['longitude']);
    }
    return null;
  }

  set location(Location? location) {
    if (location != null) {
      var locationData = <String, double?>{
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
      _userData['location'] = locationData;
    } else {
      _userData.remove('location');
    }
    _updateInstance(_userData);
  }

  /// User's identifier. It is used in [server-side rewarding](https://developer.fyber.com/hc/en-us/articles/360009923657-Server-Side-Rewarding) feature.
  ///
  /// > The User ID length must not exceed 256 characters. If it does, the Server Side Reward callback will not contain a User ID value.
  String? get id => _userData['id'];

  set id(String? id) {
    _userData['id'] = id;
    _updateInstance(_userData);
  }

  @override
  String toString() {
    return 'UserData{ $_userData }';
  }

  static UserData? _instance;
  UserData._fromMap(this._userData);

  static void _updateInstance(Map<String, dynamic> userData) async {
    await FairBidInternal._channel.invokeMethod("updateUserData", userData);
    Map<String, dynamic> currentData =
        (await (FairBidInternal._channel.invokeMapMethod("getUserData")))!.cast();
    _instance = UserData._fromMap(currentData);
  }
}

enum Gender {
  unknown,
  male,
  female,
  other,
}

class Location {
  final double? latitude;
  final double? longitude;

  Location(this.latitude, this.longitude);

  @override
  String toString() => "[$latitude, $longitude]";
}
