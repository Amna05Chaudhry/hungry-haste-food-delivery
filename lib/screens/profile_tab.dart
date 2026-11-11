import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/demo_backend.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'auth_screen.dart' show requiredField;

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.onBrowseMenu});
  final VoidCallback onBrowseMenu;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final t = Theme.of(context);
    if (user == null) return const SizedBox();
    return MaxWidth(
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('My profile', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              UserAvatar(user: user, radius: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.displayName, style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _InfoLine(Icons.mail_outline, user.email),
                  _InfoLine(Icons.phone_outlined, user.phone.isEmpty ? 'No phone number' : user.phone),
                  _InfoLine(Icons.home_outlined, user.address.isEmpty ? 'No address yet' : user.address),
                ]),
              ),
              IconButton.filledTonal(
                tooltip: 'Edit profile',
                onPressed: () => showDialog(context: context, builder: (_) => const EditProfileDialog()),
                icon: const Icon(Icons.edit_outlined),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text('Browse the menu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onBrowseMenu,
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Cart'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, Routes.cart),
            ),
            ValueListenableBuilder(
              valueListenable: themeMode,
              builder: (_, mode, _) => SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                value: mode == ThemeMode.dark,
                onChanged: (v) => themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
            if (user.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin panel'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, Routes.adminDashboard),
              ),
            if (state.backend case final DemoBackend demo)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset demo data'),
                subtitle: const Text('Restores the sample menu, accounts and orders'),
                onTap: () async {
                  await demo.reset();
                  await state.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
                  }
                },
              ),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await state.signOut();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 12),
        const Center(child: ModeBadge()),
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: c))),
      ]),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});
  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final AppUser _user = context.read<AppState>().user!;
  late final _first = TextEditingController(text: _user.firstName);
  late final _last = TextEditingController(text: _user.lastName);
  late final _phone = TextEditingController(text: _user.phone);
  late final _address = TextEditingController(text: _user.address);
  Uint8List? _photo;
  bool _busy = false;

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 256, maxHeight: 256, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photo = bytes);
    } catch (e) {
      if (mounted) showError(context, 'Could not open the photo picker: $e');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().updateProfile(
            _user.copyWith(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              phone: _phone.text.trim(),
              address: _address.text.trim(),
            ),
            photo: _photo,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(children: [
                _photo != null
                    ? CircleAvatar(radius: 40, backgroundImage: MemoryImage(_photo!))
                    : UserAvatar(user: _user, radius: 40),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: IconButton.filled(
                    tooltip: 'Change photo',
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _first,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (v) => requiredField(v, 'first name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(controller: _last, decoration: const InputDecoration(labelText: 'Last name')),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Delivery address')),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
