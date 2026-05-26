import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../injection_container.dart';
import '../../services/datasources/auth_local_datasource.dart';

class DriverReviewsScreen extends StatefulWidget {
  const DriverReviewsScreen({super.key});

  @override
  State<DriverReviewsScreen> createState() => _DriverReviewsScreenState();
}

class _DriverReviewsScreenState extends State<DriverReviewsScreen> {
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 10;
  
  String? _driverName;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<dynamic> _ratingsList = [];

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings({int? page}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (page != null) {
        _page = page;
      }
    });

    try {
      final authLocal = sl<AuthLocalDataSource>();
      final user = await authLocal.getCachedUser();
      if (user == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      final driverId = user.id;
      final token = user.accessToken;
      final baseUrl = ApiConstants.baseUrl;

      final url = '$baseUrl/api/Ratings/driver/$driverId?page=$_page&pageSize=$_pageSize';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          setState(() {
            _driverName = data['driverName'];
            _averageRating = (data['averageRating'] ?? 0.0).toDouble();
            _totalReviews = data['totalReviews'] ?? 0;
            _ratingsList = data['ratings'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      throw Exception('Không thể tải danh sách đánh giá');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);
    const accentColor = Color(0xFF076F4B);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Đánh giá của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: accentColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Đã xảy ra lỗi: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _fetchRatings(page: 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header Stats Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _driverName ?? 'Tài xế',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      _averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_totalReviews Đánh giá',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _ratingsList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Bạn chưa nhận được đánh giá nào',
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _fetchRatings(page: 1),
                              color: primaryColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _ratingsList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _ratingsList.length) {
                                    // Pagination row
                                    final hasPrev = _page > 1;
                                    final hasNext = _ratingsList.length == _pageSize;

                                    if (!hasPrev && !hasNext) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: hasPrev ? () => _fetchRatings(page: _page - 1) : null,
                                            icon: const Icon(Icons.chevron_left),
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Trang $_page'),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            onPressed: hasNext ? () => _fetchRatings(page: _page + 1) : null,
                                            icon: const Icon(Icons.chevron_right),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final rating = _ratingsList[index];
                                  final createdAt = DateTime.parse(rating['createdAt']);
                                  final ratingVal = (rating['rating'] ?? 0) as int;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                rating['userName'] ?? 'Khách hàng ẩn danh',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: List.generate(5, (starIdx) {
                                              return Icon(
                                                starIdx < ratingVal ? Icons.star_rounded : Icons.star_outline_rounded,
                                                color: Colors.amber,
                                                size: 18,
                                              );
                                            }),
                                          ),
                                          if (rating['comment'] != null &&
                                              rating['comment'].toString().trim().isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.shade100),
                                              ),
                                              child: Text(
                                                '"${rating['comment']}"',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
