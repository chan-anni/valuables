import 'package:flutter/material.dart';
import 'package:valuables/claims/claims_service.dart';

/// Bottom sheet shown when a user taps "This is mine" on a found item.
/// They describe proof of ownership and submit a claim to the finder.
class ClaimSheet extends StatefulWidget {
  final String itemId;
  final String finderId;
  final String itemTitle;

  const ClaimSheet({
    super.key,
    required this.itemId,
    required this.finderId,
    required this.itemTitle,
  });

  @override
  State<ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<ClaimSheet> {
  final _proofController = TextEditingController();
  final _claimsService = ClaimsService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final proof = _proofController.text.trim();
    if (proof.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe how you can prove this is yours')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _claimsService.submitClaim(
        itemId: widget.itemId,
        finderId: widget.finderId,
        proofDescription: proof,
      );

      if (mounted) {
        Navigator.pop(context); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim submitted! The finder will review your request.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit claim: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      // Shift sheet up when keyboard appears
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            const Text(
              'Claim this item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.itemTitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Describe something specific about this item that proves it\'s yours — '
                      'e.g. a scratch, sticker, engraving, or what\'s inside.',
                      style: TextStyle(fontSize: 13, color: primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Proof text field
            TextField(
              controller: _proofController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'e.g. There\'s a crack on the bottom-left corner and a red sticker on the back...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: primary,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Claim',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}