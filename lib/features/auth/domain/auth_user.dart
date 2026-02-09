class TawakkalUser {
  const TawakkalUser({
    required this.id,
    required this.displayName,
    required this.isGuest,
    this.email,
  });

  final String id;
  final String displayName;
  final String? email;
  final bool isGuest;

  factory TawakkalUser.guest() {
    return const TawakkalUser(id: 'guest', displayName: 'Guest', isGuest: true);
  }
}
