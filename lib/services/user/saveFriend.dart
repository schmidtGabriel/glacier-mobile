import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> saveFriend(userId, friendEmail) async {
  final docFriendRef = FirebaseFirestore.instance.collection(
    'friend_invitations',
  );
  final docRef = FirebaseFirestore.instance.collection('users');

  var friend =
      await docRef.where('email', isEqualTo: friendEmail).limit(1).get();

  var exist =
      await docFriendRef
          .where('requested_user', isEqualTo: userId)
          .where('invited_user', isEqualTo: friend.docs.first.id)
          .limit(1)
          .get();

  var exist2 =
      await docFriendRef
          .where('requested_user', isEqualTo: friend.docs.first.id)
          .where('invited_user', isEqualTo: userId)
          .limit(1)
          .get();

  if (exist.docs.isNotEmpty || exist2.docs.isNotEmpty) {
    print('Friend invitation already exists.');
    return null;
  }

  var newFriend = await docFriendRef.add({
    'requested_user': userId,
    'friend_email': friendEmail,
    'invited_user': friend.docs.isNotEmpty ? friend.docs.first.id : null,
    'created_at': FieldValue.serverTimestamp(),
    'status': 0,
  });

  if (newFriend.id.isNotEmpty) {
    docFriendRef.doc(newFriend.id).update({'uuid': newFriend.id});
  } else {
    print('Failed to create friend invitation.');
  }
  return null;
}
