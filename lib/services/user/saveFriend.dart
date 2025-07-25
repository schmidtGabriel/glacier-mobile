import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/services/SendInviteEmail.dart';

Future<FriendInvitationResponse> saveFriend(
  String userId,
  String friendEmail,
) async {
  try {
    // Validate inputs
    if (userId.isEmpty || friendEmail.isEmpty) {
      print('User ID or friend email cannot be empty');
      return FriendInvitationResponse(
        error: true,
        result: FriendInvitationResult.error,
        message: 'User ID and friend email cannot be empty',
      );
    }

    final firestore = FirebaseFirestore.instance;
    final friendInvitationsRef = firestore.collection('friend_invitations');
    final usersRef = firestore.collection('users');

    // Check if user is trying to invite themselves
    final currentUser = await usersRef.doc(userId).get();
    if (currentUser.exists && currentUser.data()?['email'] == friendEmail) {
      print('User cannot invite themselves');
      return FriendInvitationResponse(
        error: true,
        result: FriendInvitationResult.cannotInviteSelf,
        message: 'You cannot invite yourself',
      );
    }

    // Find the friend by email
    final friendQuery =
        await usersRef.where('email', isEqualTo: friendEmail).limit(1).get();

    final friendId =
        friendQuery.docs.isNotEmpty ? friendQuery.docs.first.id : null;

    // Check for existing invitations in both directions using a single query
    Query<Map<String, dynamic>> existingInvitationsQuery;

    if (friendId != null) {
      // If friend exists, check for invitations in both directions
      existingInvitationsQuery = friendInvitationsRef.where(
        Filter.or(
          Filter.and(
            Filter('requested_user', isEqualTo: userId),
            Filter('invited_user', isEqualTo: friendId),
          ),
          Filter.and(
            Filter('requested_user', isEqualTo: friendId),
            Filter('invited_user', isEqualTo: userId),
          ),
          Filter.and(
            Filter('requested_user', isEqualTo: userId),
            Filter('friend_email', isEqualTo: friendEmail),
          ),
        ),
      );
    } else {
      // If friend doesn't exist, only check by email
      existingInvitationsQuery = friendInvitationsRef.where(
        Filter.and(
          Filter('requested_user', isEqualTo: userId),
          Filter('friend_email', isEqualTo: friendEmail),
        ),
      );
    }

    final existingInvitations = await existingInvitationsQuery.limit(1).get();

    if (existingInvitations.docs.isNotEmpty) {
      return FriendInvitationResponse(
        error: true,
        result: FriendInvitationResult.alreadyExists,
        message: 'Friend invitation already exists',
      );
    }

    // Create the friend invitation with UUID in a single operation
    final newInvitationRef = friendInvitationsRef.doc();
    await newInvitationRef.set({
      'uuid': newInvitationRef.id,
      'requested_user': userId,
      'invited_to': friendEmail,
      'invited_user': friendId,
      'created_at': FieldValue.serverTimestamp(),
      'status': 0, // 0 = pending
    });
    await sendInviteEmail(friendEmail);

    return FriendInvitationResponse(
      result: FriendInvitationResult.success,
      invitationId: newInvitationRef.id,
      message: 'Friend invitation sent successfully',
    );
  } catch (e) {
    print('Error saving friend invitation: $e');
    return FriendInvitationResponse(
      error: true,
      result: FriendInvitationResult.error,
      message: 'Failed to send friend invitation: $e',
    );
  }
}

class FriendInvitationResponse {
  final FriendInvitationResult result;
  final String? invitationId;
  final String? message;
  final bool error;

  FriendInvitationResponse({
    required this.result,
    this.invitationId,
    this.message,
    this.error = false,
  });
}

enum FriendInvitationResult {
  success,
  userNotFound,
  alreadyExists,
  cannotInviteSelf,
  error,
}
