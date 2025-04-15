import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/ftp_connection/ftp_connection_bloc.dart';
import '../blocs/ftp_connection/ftp_connection_event.dart';
import '../blocs/ftp_connection/ftp_connection_state.dart';
import '../models/ftp_server.dart';
import '../widgets/connection_status_widget.dart';

class ServerConnectionScreen extends StatefulWidget {
  const ServerConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ServerConnectionScreen> createState() => _ServerConnectionScreenState();
}

class _ServerConnectionScreenState extends State<ServerConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My IoT Device');
  final _hostController = TextEditingController(text: '');
  final _portController = TextEditingController(text: '21');
  final _usernameController = TextEditingController(text: 'Anand');
  final _passwordController = TextEditingController(text: '1234');
  bool _anonymous = false;
  bool _savePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to FTP Server'),
      ),
      body: BlocConsumer<FtpConnectionBloc, FtpConnectionState>(
        listener: (context, state) {
          if (state.status == FtpConnectionStatus.connected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected to FTP server successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate to file browser after successful connection
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.of(context).pushReplacementNamed('/file_browser');
            });
          } else if (state.status == FtpConnectionStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_outlined, size: 32),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Server Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const ConnectionStatusWidget(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Connection Name',
                              prefixIcon: Icon(Icons.bookmark_border),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name for this connection';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hostController,
                            decoration: const InputDecoration(
                              labelText: 'Host',
                              prefixIcon: Icon(Icons.dns),
                              hintText: 'e.g., 192.168.1.100',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the server host';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              prefixIcon: Icon(Icons.settings_ethernet),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the port number';
                              }
                              final port = int.tryParse(value);
                              if (port == null || port <= 0 || port > 65535) {
                                return 'Please enter a valid port number (1-65535)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            title: const Text('Anonymous Login'),
                            value: _anonymous,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _anonymous = value ?? false;
                              });
                            },
                          ),
                          if (!_anonymous) ...[
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (!_anonymous && (value == null || value.isEmpty)) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (!_anonymous && (value == null || value.isEmpty)) {
                                  return 'Please enter a password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              title: const Text('Save Password'),
                              value: _savePassword,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                setState(() {
                                  _savePassword = value ?? true;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: Text(state.status == FtpConnectionStatus.connecting
                        ? 'Connecting...'
                        : 'Connect to Server'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: state.status == FtpConnectionStatus.connecting
                        ? null
                        : _connectToServer,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _connectToServer() {
    if (_formKey.currentState?.validate() ?? false) {
      final server = FtpServer(
        name: _nameController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _anonymous ? 'anonymous' : _usernameController.text,
        password: _anonymous ? '' : _passwordController.text,
        anonymous: _anonymous,
        savePassword: _savePassword,
      );

      context.read<FtpConnectionBloc>().add(FtpConnect(server));
    }
  }
}