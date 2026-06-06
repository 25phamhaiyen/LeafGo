import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:leafgo_app/models/admin/statistics/statistics_model.dart';
import 'package:flutter/foundation.dart';

class AIService {
  // TODO: Insert your actual Gemini API key here or load from .env
  // Get an API key from https://aistudio.google.com/
  static const String _apiKey = String.fromEnvironment(
    'AIzaSyC4f3yFD4aambW0iXZdaNJuPo2bcDTak-M',
    defaultValue: 'AIzaSyC4f3yFD4aambW0iXZdaNJuPo2bcDTak-M',
  );

  Future<String> generateAdminInsight(StatisticsModel stats) async {
    if (_apiKey.isEmpty) {
      return 'Vui lòng cung cấp GEMINI_API_KEY để sử dụng tính năng phân tích AI.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

      final prompt =
          '''
Bạn là một giám đốc chiến lược dữ liệu thông minh và thân thiện cho ứng dụng đặt xe công nghệ LeafGo (giống Grab).
Dưới đây là số liệu thống kê kinh doanh ngày hôm nay:
- Tổng số khách hàng: ${stats.totalUsers}
- Tổng số tài xế: ${stats.totalDrivers} (${stats.onlineDrivers} đang online)
- Doanh thu hôm nay: ${stats.todayRevenue} VNĐ
- Tổng chuyến đi đã hoàn thành: ${stats.totalCompletedRides}
- Doanh thu tháng này: ${stats.thisMonthRevenue} VNĐ

Dựa vào các số liệu trên, hãy viết một đoạn nhận xét và lời khuyên ngắn gọn (khoảng 3-4 câu) bằng tiếng Việt cho người quản trị (Admin).
Hãy dùng từ ngữ khích lệ, chuyên nghiệp và có dùng emoji. Không cần lặp lại chính xác các con số nếu không cần thiết, tập trung vào ý nghĩa của nó.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? 'Không thể tạo phân tích vào lúc này.';
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return 'Có lỗi xảy ra khi gọi AI: $e';
    }
  }
}
