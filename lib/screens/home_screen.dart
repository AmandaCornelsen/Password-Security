import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:passwordsecurity/screens/new_password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _visible = {}; // ids of passwords currently visible

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  Future<void> _deletePassword(String id) async {
    await _firestore.collection('passwords').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Usuário não autenticado')),
      );
    }

    final stream = _firestore
        .collection('passwords')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await _signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo, ${user.email ?? 'Usuário'}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Suas senhas salvas:'),
                    ],
                  ),
                ),
                // Premium banner using Lottie animation as an image-like banner
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Lottie.asset('assets/lottie/Password.json'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erro: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Nenhuma senha salva.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final id = doc.id;
                    final title = data['title'] ?? '';
                    final username = data['username'] ?? '';
                    final password = data['password'] ?? '';

                    final visible = _visible.contains(id);

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (username.isNotEmpty) Text('Usuário: $username'),
                            const SizedBox(height: 4),
                            Text(visible ? 'Senha: $password' : 'Senha: ••••••'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                  visible ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  if (visible) {
                                    _visible.remove(id);
                                  } else {
                                    _visible.add(id);
                                  }
                                });
                              },
                              tooltip: visible ? 'Ocultar senha' : 'Exibir senha',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar'),
                                    content: const Text(
                                        'Deseja excluir esta senha?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _deletePassword(id);
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                        const SnackBar(content: Text('Senha excluída')));
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                        SnackBar(content: Text('Erro ao excluir: $e')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await Clipboard.setData(ClipboardData(text: password));
                            if (!mounted) return;
                            messenger.showSnackBar(
                                const SnackBar(content: Text('Senha copiada para o clipboard')));
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                                SnackBar(content: Text('Erro ao copiar: $e')));
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
          );
        },
        tooltip: 'Nova senha',
        child: const Icon(Icons.add),
      ),
    );
  }
}
