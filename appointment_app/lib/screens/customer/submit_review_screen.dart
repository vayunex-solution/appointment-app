import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class SubmitReviewScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const SubmitReviewScreen({super.key, required this.booking});

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.post(ApiConfig.submitReview, {
        'appointment_id': widget.booking['id'],
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted! Thank you'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to submit')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.booking['service_name'] ?? '';
    final providerName = widget.booking['provider_name'] ?? widget.booking['shop_name'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Write Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 50, color: AppTheme.accentColor),
            const SizedBox(height: 16),
            Text('How was your experience?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('$serviceName at $providerName', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 32),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 44,
                      color: index < _rating ? Colors.amber : Colors.white38,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating == 0 ? 'Tap to rate' : ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
              style: TextStyle(color: _rating > 0 ? Colors.amber : Colors.white38, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Comment
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Write your comment (optional)',
                hintText: 'Share your experience...',
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('SUBMIT REVIEW'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
