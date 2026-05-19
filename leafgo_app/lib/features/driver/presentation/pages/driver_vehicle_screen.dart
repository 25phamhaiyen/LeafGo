import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/features/booking/presentation/bloc/booking_bloc.dart';
import '../bloc/driver_bloc.dart';

class DriverVehicleScreen extends StatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(DriverLoadProfile());
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  void _populateFields(dynamic vehicle) {
    if (vehicle != null) {
      _plateCtrl.text = vehicle.licensePlate;
      _brandCtrl.text = vehicle.vehicleBrand;
      _modelCtrl.text = vehicle.vehicleModel;
      _colorCtrl.text = vehicle.vehicleColor;
      _selectedTypeId = vehicle.vehicleTypeId;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại phương tiện'), backgroundColor: Colors.red),
      );
      return;
    }

    context.read<DriverBloc>().add(
          DriverUpdateVehicle(
            vehicleTypeId: _selectedTypeId!,
            licensePlate: _plateCtrl.text.trim(),
            vehicleBrand: _brandCtrl.text.trim(),
            vehicleModel: _modelCtrl.text.trim(),
            vehicleColor: _colorCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông Tin Phương Tiện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: BlocConsumer<DriverBloc, DriverState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: Colors.red.shade700),
            );
          }
          if (state.vehicle != null && _plateCtrl.text.isEmpty) {
            _populateFields(state.vehicle);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.vehicle == null) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final bookingState = context.watch<BookingBloc>().state;
          final vehicleTypes = bookingState.vehicleTypes;

          if (_selectedTypeId == null && vehicleTypes.isNotEmpty) {
            _selectedTypeId = vehicleTypes.first.id;
          }

          final hasVehicle = state.vehicle != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryColor.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.directions_car, size: 64, color: primaryColor),
                        const SizedBox(height: 12),
                        Text(
                          hasVehicle ? 'Phương tiện đã đăng ký' : 'Chưa đăng ký phương tiện',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasVehicle 
                              ? 'Bạn có thể chỉnh sửa thông tin phương tiện bên dưới' 
                              : 'Vui lòng cung cấp thông tin phương tiện để bắt đầu đón khách',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Loại phương tiện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedTypeId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    items: vehicleTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTypeId = val),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Biển số xe'),
                  TextFormField(
                    controller: _plateCtrl,
                    decoration: _inputDec('Ví dụ: 59A-123.45', Icons.badge_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập biển số' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Hãng xe'),
                  TextFormField(
                    controller: _brandCtrl,
                    decoration: _inputDec('Ví dụ: Honda, Yamaha, Toyota', Icons.branding_watermark_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập hãng xe' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Dòng xe'),
                  TextFormField(
                    controller: _modelCtrl,
                    decoration: _inputDec('Ví dụ: Vision, Wave, Vios', Icons.model_training_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập dòng xe' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Màu xe'),
                  TextFormField(
                    controller: _colorCtrl,
                    decoration: _inputDec('Ví dụ: Đen, Trắng, Đỏ', Icons.color_lens_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập màu xe' : null,
                  ),
                  const SizedBox(height: 36),

                  ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            hasVehicle ? 'Cập nhật thông tin' : 'Đăng ký phương tiện',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
    );
  }

  InputDecoration _inputDec(String hint, IconData prefix) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefix, size: 20, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
