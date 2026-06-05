import '../models/user_model.dart';

class DummyUser {
  static const UserModel currentUser = UserModel(
    id: '1',
    name: 'Marcel Yoh',
    avatarUrl: 'assets/images/profile.jpg',
    notificationCount: 3,
    isNetworkImage: false,
  );
}