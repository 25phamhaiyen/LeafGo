// lib/features/admin/presentation/pages/vehicle_type_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/models/admin/vehicle/vehicle_type.dart';

import '../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';

class VehicleTypeManagementScreen extends StatelessWidget {
  const VehicleTypeManagementScreen({super.key});

  String _token(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.accessToken : '';
  }

  void _fetch(BuildContext context) {
    context.read<AdminBloc>().add(AdminFetchVehicleTypes(_token(context)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminBloc>()..add(AdminFetchVehicleTypes(_token(context))),
      child: Builder(
        builder: (context) {
          return BlocListener<AdminBloc, AdminState>(
            listener: (context, state) {
              if (state is AdminActionSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                _fetch(context);
              }
              if (state is AdminFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${state.message}')),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Quản lý loại xe'),
                actions: [
                  IconButton(
                    tooltip: 'Thêm loại xe',
                    icon: const Icon(Icons.add_road),
                    onPressed: () => _showForm(context),
                  ),
                ],
              ),
              body: BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AdminVehicleTypesLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async => _fetch(context),
                      child: state.vehicleTypes.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 160),
                                Center(child: Text('Chưa có loại xe.')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: state.vehicleTypes.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final type = state.vehicleTypes[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: type.isActive
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.18),
                                    child: Icon(
                                      Icons.local_taxi,
                                      color: type.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(type.name),
                                  subtitle: Text(
                                    'Mở cửa ${_money(type.basePrice)} • ${_money(type.pricePerKm)}/km\n'
                                    '${type.totalDrivers} tài xế • ${type.totalRides} chuyến',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showForm(context, type: type);
                                      }
                                      if (value == 'delete') {
                                        _confirmDelete(context, type);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Sửa'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    );
                  }
                  if (state is AdminFailure) {
                    return Center(child: Text('Lỗi: ${state.message}'));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VehicleTypeModel type,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa loại xe'),
        content: Text('Xóa loại xe ${type.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<AdminBloc>().add(
      AdminDeleteVehicleType(accessToken: _token(context), id: type.id),
    );
  }

  Future<void> _showForm(BuildContext context, {VehicleTypeModel? type}) async {
    final nameCtrl = TextEditingController(text: type?.name ?? '');
    final baseCtrl = TextEditingController(
      text: type == null ? '' : type.basePrice.toStringAsFixed(0),
    );
    final kmCtrl = TextEditingController(
      text: type == null ? '' : type.pricePerKm.toStringAsFixed(0),
    );
    final descCtrl = TextEditingController(text: type?.description ?? '');
    var isActive = type?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(type == null ? 'Thêm loại xe' : 'Sửa loại xe'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên'),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: baseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Giá mở cửa',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _positiveNumber,
                    ),
                    TextFormField(
                      controller: kmCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Giá mỗi km',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _positiveNumber,
                    ),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    if (type != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đang hoạt động'),
                        value: isActive,
                        onChanged: (value) =>
                            setDialogState(() => isActive = value),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final bloc = context.read<AdminBloc>();
                  final basePrice = double.parse(baseCtrl.text.trim());
                  final pricePerKm = double.parse(kmCtrl.text.trim());
                  if (type == null) {
                    bloc.add(
                      AdminCreateVehicleType(
                        accessToken: _token(context),
                        name: nameCtrl.text.trim(),
                        basePrice: basePrice,
                        pricePerKm: pricePerKm,
                        description: descCtrl.text.trim(),
                      ),
                    );
                  } else {
                    bloc.add(
                      AdminUpdateVehicleType(
                        accessToken: _token(context),
                        id: type.id,
                        name: nameCtrl.text.trim(),
                        basePrice: basePrice,
                        pricePerKm: pricePerKm,
                        description: descCtrl.text.trim(),
                        isActive: isActive,
                      ),
                    );
                  }
                  Navigator.pop(dialogContext);
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    baseCtrl.dispose();
    kmCtrl.dispose();
    descCtrl.dispose();
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
  return null;
}

String? _positiveNumber(String? value) {
  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
  final parsed = double.tryParse(value.trim());
  if (parsed == null || parsed < 0) return 'Số không hợp lệ';
  return null;
}

String _money(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return '$bufferđ';
}
