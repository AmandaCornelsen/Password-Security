import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Generation options
  int _length = 12;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _numbers = true;
  bool _symbols = false;
  bool _showOptions = false;

  String? _generatedPassword;
  bool _isGenerating = false;

  final String _apiBase = 'https://safekey-api-a1bd9aa97953.herokuapp.com';

  Future<void> _generatePassword() async {
    setState(() {
      _isGenerating = true;
      _generatedPassword = null;
    });

    try {
      final uri = Uri.parse('$_apiBase/generate');
      final body = jsonEncode({
        'size': _length,
        'uppercase': _uppercase,
        'lowercase': _lowercase,
        'numbers': _numbers,
        'symbols': _symbols,
      });

      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        String pw = '';
        if (json is Map && json.containsKey('password')) {
          pw = json['password'].toString();
        } else if (json is Map && json.containsKey('result')) {
          pw = json['result'].toString();
        } else if (json is Map && json.values.isNotEmpty) {
          pw = json.values.first.toString();
        } else {
          pw = resp.body.toString();
        }
        setState(() => _generatedPassword = pw);
      } else {
        final msg = 'Serviço indisponível (status ${resp.statusCode})';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar senha: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveToFirestore(String label) async {
    if (_generatedPassword == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gere uma senha antes de salvar')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('passwords').add({
        'title': label,
        'username': '',
        'password': _generatedPassword,
        'uid': user.uid,
        'createdAt': Timestamp.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha salva')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  Future<void> _onSavePressed() async {
    // ask for label
    final controller = TextEditingController();
    final label = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rótulo da senha'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ex: Conta do banco'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );

    if (label != null && label.isNotEmpty) {
      await _saveToFirestore(label);
    } else if (label != null && label.isEmpty) {
      // empty label -> use default
      await _saveToFirestore('Sem rótulo');
    }
  }

  // no-op dispose

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de Senhas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Password Security',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Gerador via SafeKey API',
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Opções de geração', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Tamanho: $_length')),
                        IconButton(
                          icon: Icon(_showOptions ? Icons.expand_less : Icons.expand_more),
                          onPressed: () => setState(() => _showOptions = !_showOptions),
                        )
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          Slider(
                            value: _length.toDouble(),
                            min: 4,
                            max: 64,
                            divisions: 60,
                            label: '$_length',
                            onChanged: (v) => setState(() => _length = v.round()),
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('Maiúsculas')),
                              Switch(value: _uppercase, onChanged: (v) => setState(() => _uppercase = v)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('Minúsculas')),
                              Switch(value: _lowercase, onChanged: (v) => setState(() => _lowercase = v)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('Números')),
                              Switch(value: _numbers, onChanged: (v) => setState(() => _numbers = v)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('Símbolos')),
                              Switch(value: _symbols, onChanged: (v) => setState(() => _symbols = v)),
                            ],
                          ),
                        ],
                      ),
                      crossFadeState: _showOptions ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generatePassword,
                      icon: const Icon(Icons.refresh),
                      label: Text(_isGenerating ? 'Gerando...' : 'Gerar senha'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PasswordResultWidget(
              password: _generatedPassword,
              isLoading: _isGenerating,
              onCopy: (p) async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: p));
                messenger.showSnackBar(const SnackBar(content: Text('Copiado para o clipboard')));
              },
              onRegenerate: _generatePassword,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onSavePressed,
        tooltip: 'Salvar senha',
        child: const Icon(Icons.save),
      ),
    );
  }
}

class PasswordResultWidget extends StatefulWidget {
  final String? password;
  final bool isLoading;
  final Future<void> Function(String) onCopy;
  final Future<void> Function() onRegenerate;

  const PasswordResultWidget({
    super.key,
    required this.password,
    required this.isLoading,
    required this.onCopy,
    required this.onRegenerate,
  });

  @override
  State<PasswordResultWidget> createState() => _PasswordResultWidgetState();
}

class _PasswordResultWidgetState extends State<PasswordResultWidget> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.password == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Nenhuma senha gerada ainda.'),
              const SizedBox(height: 8),
              ElevatedButton.icon(onPressed: widget.onRegenerate, icon: const Icon(Icons.refresh), label: const Text('Gerar')),
            ],
          ),
        ),
      );
    }

    final display = _visible ? widget.password! : '•' * widget.password!.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Resultado', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: SelectableText(display, style: const TextStyle(fontSize: 18))),
                IconButton(
                  icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _visible = !_visible),
                  tooltip: _visible ? 'Ocultar' : 'Exibir',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: () => widget.onCopy(widget.password!), icon: const Icon(Icons.copy), label: const Text('Copiar'))),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: widget.onRegenerate, icon: const Icon(Icons.refresh), label: const Text('Gerar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
