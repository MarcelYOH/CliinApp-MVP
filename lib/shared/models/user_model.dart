class UserModel {
  final String id;
  final String name;
  final String avatarUrl;
  final int notificationCount;
  final bool isNetworkImage;

  const UserModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.notificationCount,
    this.isNetworkImage = false,
  });
}