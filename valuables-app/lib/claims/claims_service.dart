import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:valuables/chat/chat_service.dart';

class ClaimsService {
  final _supabase = Supabase.instance.client;
  final _authService = GetIt.I<AuthService>();
  final _chatService = GetIt.I<ChatService>();

  /// Submit a claim on a found item. Called by the person who lost the item.
  Future<void> submitClaim({
    required String itemId,
    required String finderId,
    required String proofDescription,
  }) async {
    final currentUser = _authService.getCurrentUserSession()?.user;
    if (currentUser == null) throw Exception('Not logged in');

    await _supabase.from('claims').insert({
      'item_id': itemId,
      'claimant_id': currentUser.id,
      'finder_id': finderId,
      'proof_description': proofDescription,
      'status': 'pending',
    });
  }

  /// Fetch all pending claims where the current user is the finder.
  /// Fetches claimant username separately to avoid cross-schema FK issues.
  Future<List<Map<String, dynamic>>> fetchPendingClaimsForFinder() async {
    final currentUser = _authService.getCurrentUserSession()?.user;
    if (currentUser == null) return [];

    // Step 1: fetch claims + item info (no user join)
    final result = await _supabase
        .from('claims')
        .select('''
          id,
          proof_description,
          created_at,
          status,
          item_id,
          claimant_id,
          items (title, image_url)
        ''')
        .eq('finder_id', currentUser.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final claims = List<Map<String, dynamic>>.from(result);

    // Step 2: for each claim, fetch the claimant's username from public.users
    for (int i = 0; i < claims.length; i++) {
      final claimantId = claims[i]['claimant_id'] as String?;
      if (claimantId == null) continue;

      try {
        final userResult = await _supabase
            .from('users')
            .select('id, username')
            .eq('id', claimantId)
            .single();

        // Attach it under 'claimant' key so claim_requests_page.dart works unchanged
        claims[i] = {
          ...claims[i],
          'claimant': userResult,
        };
      } catch (_) {
        // If user lookup fails, just leave claimant as null — UI handles it gracefully
        claims[i] = {
          ...claims[i],
          'claimant': null,
        };
      }
    }

    return claims;
  }

  /// Accept a claim: creates a chat room, adds both users, updates claim status.
  Future<String> acceptClaim({
    required String claimId,
    required String claimantId,
    required String itemId,
    required String itemTitle,
  }) async {
    final currentUser = _authService.getCurrentUserSession()?.user;
    if (currentUser == null) throw Exception('Not logged in');

    // 1. Create the chat room
    final room = await _chatService.createRoom(
      name: itemTitle,
      itemId: itemId,
    );
    if (room == null) throw Exception('Failed to create room');
    final roomId = room['id'] as String;

    // 2. Add both users to the room
    await _chatService.addUsersToRoom([currentUser.id, claimantId], roomId);

    // 3. Update the claim to accepted and store the room id
    await _supabase.from('claims').update({
      'status': 'accepted',
      'chat_room_id': roomId,
    }).eq('id', claimId);

    return roomId;
  }

  /// Deny a claim.
  Future<void> denyClaim({required String claimId}) async {
    await _supabase.from('claims').update({
      'status': 'denied',
    }).eq('id', claimId);
  }

  /// Returns the count of pending claims for the current user (as finder).
  Future<int> fetchPendingClaimCount() async {
    final currentUser = _authService.getCurrentUserSession()?.user;
    if (currentUser == null) return 0;

    final result = await _supabase
        .from('claims')
        .select('id')
        .eq('finder_id', currentUser.id)
        .eq('status', 'pending');

    return (result as List).length;
  }
}