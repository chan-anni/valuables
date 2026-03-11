import 'package:flutter/material.dart';
import 'package:valuables/claims/claims_service.dart';
import 'package:valuables/screens/chat_screen.dart';

class ClaimRequestsPage extends StatefulWidget {
  const ClaimRequestsPage({super.key});

  @override
  State<ClaimRequestsPage> createState() => _ClaimRequestsPageState();
}

class _ClaimRequestsPageState extends State<ClaimRequestsPage> {
  final _claimsService = ClaimsService();
  late Future<List<Map<String, dynamic>>> _claimsFuture;

  @override
  void initState() {
    super.initState();
    _claimsFuture = _claimsService.fetchPendingClaimsForFinder();
  }

  void _reload() {
    setState(() {
      _claimsFuture = _claimsService.fetchPendingClaimsForFinder();
    });
  }

  Future<void> _accept(Map<String, dynamic> claim) async {
    final itemData = claim['items'] as Map<String, dynamic>?;
    final claimantId = claim['claimant_id'] as String;

    try {
      final roomId = await _claimsService.acceptClaim(
        claimId: claim['id'] as String,
        claimantId: claimantId,
        itemId: claim['item_id'] as String,
        itemTitle: itemData?['title'] as String? ?? 'Item',
      );

      if (mounted) {
        _reload();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatRoom: roomId,
              otherUserId: claimantId, // pass claimant so AppBar shows their name
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept claim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deny(Map<String, dynamic> claim) async {
    final claimantData = claim['claimant'] as Map<String, dynamic>?;
    final username = claimantData?['username'] as String? ?? 'this person';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny claim?'),
        content: Text('Are you sure you want to deny $username\'s claim?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deny', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _claimsService.denyClaim(claimId: claim['id'] as String);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deny claim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _timeAgo(String createdAt) {
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Requests'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _claimsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final claims = snapshot.data ?? [];

          if (claims.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final claim = claims[index];
              final itemData = claim['items'] as Map<String, dynamic>?;
              final claimantData = claim['claimant'] as Map<String, dynamic>?;
              final imageUrl = itemData?['image_url'] as String?;
              final itemTitle = itemData?['title'] as String? ?? 'Unknown item';
              final username = claimantData?['username'] as String? ?? 'Someone';
              final proof = claim['proof_description'] as String? ?? '';
              final createdAt = claim['created_at'] as String? ?? '';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: avatar + name + time
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                isDark ? Colors.grey[700] : Colors.grey[200],
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl == null
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'says they own: $itemTitle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _timeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Proof description
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Their proof:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(proof, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Accept / Deny buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _deny(claim),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Deny'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _accept(claim),
                              style: FilledButton.styleFrom(
                                backgroundColor: primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}