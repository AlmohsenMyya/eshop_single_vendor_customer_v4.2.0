class SearchedAdmin {
  final String? id;
  final String? username;
  final String? email;
  final String? storeName;
  final String? image;

  SearchedAdmin({
    this.id,
    this.username,
    this.email,
    this.storeName,
    this.image,
  });

  SearchedAdmin copyWith({
    String? id,
    String? username,
    String? email,
    String? storeName,
    String? image,
  }) {
    return SearchedAdmin(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      storeName: storeName ?? this.storeName,
      image: image ?? this.image,
    );
  }

  SearchedAdmin.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        username = json['username'] as String?,
        email = json['email'] as String?,
        storeName = json['store_name'] as String?,
        image = json['image'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'store_name': storeName,
        'image': image
      };
}
