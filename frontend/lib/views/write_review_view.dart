import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import 'widgets/rating_widgets.dart';

class WriteReviewView extends ConsumerStatefulWidget {
  final int? productId;
  final int? shopId;
  final int? reviewId; // null if creating, non-null if editing
  final int? initialRating;
  final String? initialComment;

  const WriteReviewView({
    super.key,
    this.productId,
    this.shopId,
    this.reviewId,
    this.initialRating,
    this.initialComment,
  });

  @override
  ConsumerState<WriteReviewView> createState() => _WriteReviewViewState();
}

class _WriteReviewViewState extends ConsumerState<WriteReviewView> {
  final _formKey = GlobalKey<FormState>();
  late int _ratingValue;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _ratingValue = widget.initialRating ?? 5;
    _commentController = TextEditingController(
      text: widget.initialComment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final comment = _commentController.text.trim();
    final opsNotifier = ref.read(reviewOpsProvider.notifier);

    Map<String, dynamic>? result;
    if (widget.reviewId != null) {
      // Editing
      result = await opsNotifier.updateReview(
        widget.reviewId!,
        ratingValue: _ratingValue,
        comment: comment,
        productId: widget.productId,
        shopId: widget.shopId,
      );
    } else {
      // Creating
      result = await opsNotifier.createReview(
        productId: widget.productId,
        shopId: widget.shopId,
        ratingValue: _ratingValue,
        comment: comment,
      );
    }

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reviewId != null
                  ? 'Review updated successfully!'
                  : 'Review submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back
        if (widget.productId != null) {
          context.go('/products/${widget.productId}');
        } else if (widget.shopId != null) {
          context.go('/shops/${widget.shopId}');
        } else {
          context.go('/');
        }
      } else {
        final error = ref.read(reviewOpsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opsState = ref.watch(reviewOpsProvider);
    final isEditing = widget.reviewId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Your Review' : 'Write a Review'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.productId != null) {
              context.go('/products/${widget.productId}');
            } else if (widget.shopId != null) {
              context.go('/shops/${widget.shopId}');
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'How would you rate it now?'
                        : 'How would you rate this item?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: StarRatingWidget(
                      rating: _ratingValue.toDouble(),
                      size: 40,
                      onRatingChanged: (val) {
                        setState(() => _ratingValue = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tell us more about your experience',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe what you liked or disliked...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter some feedback comment';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: opsState.isLoading ? null : _submitReview,
                      child: opsState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? 'Update Review' : 'Submit Review',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
