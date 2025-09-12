import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getUserFriends.dart';

typedef FriendSelected = void Function(UserResource user);
typedef NewFriendCreated = void Function(String name, String emailOrPhone);

class FriendAutocomplete extends StatefulWidget {
  final UserResource? value;
  final FriendSelected onFriendSelected;
  final NewFriendCreated? onNewFriendCreated;
  final String hintText;
  final TextEditingController? controller;
  final GlobalKey<FormState>? formKey;

  const FriendAutocomplete({
    super.key,
    required this.value,
    required this.onFriendSelected,
    this.onNewFriendCreated,
    this.hintText = 'Search friends...',
    this.controller,
    this.formKey,
  });

  @override
  State<FriendAutocomplete> createState() => _FriendAutocompleteState();
}

class _FriendAutocompleteState extends State<FriendAutocomplete> {
  late TextEditingController _controller;
  List<FriendResource> _allFriends = [];
  List<FriendResource> _filteredFriends = [];
  final bool _isLoading = false;
  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isSettingTextProgrammatically = false;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please choose an user';
          }
          return null;
        },
        onTapOutside: (event) {
          if (_controller.text.isEmpty) FocusScope.of(context).unfocus();
        },
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,

          suffixIcon:
              _isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : Icon(Icons.search),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _hideDropdown();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.value != null) {
      _controller.text = widget.value!.name;
    }
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    loadFriends();
  }

  void loadFriends() async {
    try {
      _allFriends = (await getUserFriends()).cast<FriendResource>();
    } catch (e) {
      print('Error fetching friends: $e');
      _allFriends = [];
    }
  }

  Widget _buildAddNewFriendOption() {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.blue, size: 20),
      ),
      title: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, child) {
          return Text(
            'Add "${value.text}"',
            style: const TextStyle(fontWeight: FontWeight.w500),
          );
        },
      ),
      subtitle: const Text('Tap to add as new friend'),
      onTap: () {
        _hideDropdown();
        _showAddFriendBottomSheet();
      },
    );
  }

  Widget _buildDropdownContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredFriends.isEmpty && _controller.text.isNotEmpty) {
      return _buildAddNewFriendOption();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        final friendResource = _filteredFriends[index];
        final friend = friendResource.friend;

        if (friend == null) return const SizedBox.shrink();

        return ListTile(
          leading: UserAvatar(
            pictureUrl: friend.profilePic,
            userName: friend.name,
            size: 32,
          ),
          title: Text(
            friend.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            friend.email,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          onTap: () {
            _isSettingTextProgrammatically = true;
            _controller.text = friend.name;
            _hideDropdown();
            widget.onFriendSelected(friend);
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Full screen gesture detector to dismiss keyboard on tap outside
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _focusNode.unfocus(); // Dismiss keyboard
                    _hideDropdown(); // Hide dropdown
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
                ),
              ),
              // The actual dropdown - positioned relative to the input field
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height),
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: size.width,
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      minHeight: 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap:
                          () {}, // Prevent tap from bubbling up to the full screen detector
                      child: _buildDropdownContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _filterFriends(String query) {
    if (query.isEmpty) {
      _hideDropdown();
      setState(() {
        _filteredFriends = [];
      });
      return;
    }

    final filtered =
        _allFriends.where((friendResource) {
          final friend = friendResource.friend;
          if (friend == null) return false;

          final nameMatch = friend.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final emailMatch = friend.email.toLowerCase().contains(
            query.toLowerCase(),
          );

          return nameMatch || emailMatch;
        }).toList();

    setState(() {
      _filteredFriends = filtered;
    });

    _showDropdownOverlay();
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _filterFriends(_controller.text);
    } else {
      _hideDropdown();
    }
  }

  void _onTextChanged() {
    // Don't show dropdown if text was changed programmatically
    if (_isSettingTextProgrammatically) {
      _isSettingTextProgrammatically = false;
      return;
    }

    if (widget.formKey?.currentState != null) {
      widget.formKey?.currentState!.validate();
    }

    _filterFriends(_controller.text);
  }

  void _showAddFriendBottomSheet() {
    final nameController = TextEditingController(text: _controller.text);
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Friend',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email or Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final emailOrPhone = emailController.text.trim();

                        if (name.isNotEmpty && emailOrPhone.isNotEmpty) {
                          widget.onNewFriendCreated?.call(name, emailOrPhone);
                          _isSettingTextProgrammatically = true;
                          _controller.text = name;
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in both fields'),
                            ),
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDropdownOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }
}
