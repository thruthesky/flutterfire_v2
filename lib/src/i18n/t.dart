class I18N {
  UserTranslations user = UserTranslations();
  ChatTranslations chat = ChatTranslations();
  UploadTranslations upload = UploadTranslations();
  CategoryTranslations category = CategoryTranslations();
  PostTranslations post = PostTranslations();
}

class UserTranslations {
  String loginFirst = 'Please login first';
}

class ChatTranslations {
  String noChatRooms = 'No chat rooms';
  String roomMenu = 'Chat Room Menu';
}

class UploadTranslations {
  String chooseFrom = "Choose upload from...";
}

class CategoryTranslations {
  String noCategory = 'No category';
}

class PostTranslations {
  String noPost = 'No post';
}

final tr = I18N();
