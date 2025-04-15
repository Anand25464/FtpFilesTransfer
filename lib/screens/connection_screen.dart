import 'package:flutter/material.dart';
import 'package:ftp_file_transfer/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/ftp_service.dart';
import '../models/ftp_connection.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _usernameController = TextEditingController(text: 'anonymous');
  final _passwordController = TextEditingController();
  
  bool _isAnonymous = true;
  bool _isPassive = true;
  bool _isSecure = false;
  int _timeoutSeconds = 30;
  
  bool _isLoading = false;
  List<FtpConnection> _savedConnections = [];
  
  @override
  void initState() {
    super.initState();
    _loadSavedConnections();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConnections() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = prefs.getStringList('saved_connections') ?? [];
      
      setState(() {
        _savedConnections = connectionsJson
            .map((json) => FtpConnection.fromJson(jsonDecode(json)))
            .toList();
      });
    } catch (e) {
      // Handle error
      _showErrorSnackBar('Failed to load saved connections');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConnection(FtpConnection connection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = _savedConnections
          .map((conn) => jsonEncode(conn.toJson()))
          .toList();
          
      // Add new connection if it doesn't exist
      if (!_savedConnections.any((conn) => conn.name == connection.name)) {
        connectionsJson.add(jsonEncode(connection.toJson()));
        _savedConnections.add(connection);
      }
      
      await prefs.setStringList('saved_connections', connectionsJson);
    } catch (e) {
      // Handle error
      _showErrorSnackBar('Failed to save connection');
    }
  }

  Future<void> _deleteConnection(FtpConnection connection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _savedConnections.removeWhere((conn) => conn.name == connection.name);
      });
      
      final connectionsJson = _savedConnections
          .map((conn) => jsonEncode(conn.toJson()))
          .toList();
          
      await prefs.setStringList('saved_connections', connectionsJson);
    } catch (e) {
      // Handle error
      _showErrorSnackBar('Failed to delete connection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ftpService = Provider.of<FtpService>(context);
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Saved connections section
                  if (_savedConnections.isNotEmpty) ...[
                    const Text(
                      'Saved Connections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedConnections.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final connection = _savedConnections[index];
                          return ListTile(
                            title: Text(connection.name),
                            subtitle: Text('${connection.host}:${connection.port}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editConnection(connection),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDeleteConnection(connection),
                                ),
                              ],
                            ),
                            onTap: () => _connectToServer(ftpService, connection),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // New connection form
                  const Text(
                    'New Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Connection name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Connection Name',
                                hintText: 'My IoT Device',
                                prefixIcon: Icon(Icons.bookmark),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Host
                            TextFormField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                labelText: 'Host',
                                hintText: 'ftp.example.com or 192.168.1.100',
                                prefixIcon: Icon(Icons.dns),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a host';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Port
                            TextFormField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                prefixIcon: Icon(Icons.router),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a port';
                                }
                                final port = int.tryParse(value);
                                if (port == null || port <= 0 || port > 65535) {
                                  return 'Please enter a valid port (1-65535)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Anonymous login
                            SwitchListTile(
                              title: const Text('Anonymous Login'),
                              value: _isAnonymous,
                              onChanged: (value) {
                                setState(() {
                                  _isAnonymous = value;
                                  if (value) {
                                    _usernameController.text = 'anonymous';
                                    _passwordController.text = '';
                                  }
                                });
                              },
                            ),
                            
                            // Username and Password (if not anonymous)
                            if (!_isAnonymous) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (!_isAnonymous && (value == null || value.isEmpty)) {
                                    return 'Please enter a username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                              ),
                            ],
                            
                            const Divider(height: 32),
                            
                            // Advanced options
                            ExpansionTile(
                              title: const Text('Advanced Options'),
                              children: [
                                SwitchListTile(
                                  title: const Text('Passive Mode'),
                                  subtitle: const Text('Recommended for most connections'),
                                  value: _isPassive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isPassive = value;
                                    });
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('Secure FTP (FTPS)'),
                                  subtitle: const Text('Use TLS/SSL encryption'),
                                  value: _isSecure,
                                  onChanged: (value) {
                                    setState(() {
                                      _isSecure = value;
                                    });
                                  },
                                ),
                                ListTile(
                                  title: const Text('Connection Timeout'),
                                  subtitle: Text('$_timeoutSeconds seconds'),
                                  trailing: SizedBox(
                                    width: 140,
                                    child: Slider(
                                      value: _timeoutSeconds.toDouble(),
                                      min: 5,
                                      max: 120,
                                      divisions: 23,
                                      label: '$_timeoutSeconds seconds',
                                      onChanged: (value) {
                                        setState(() {
                                          _timeoutSeconds = value.round();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Connect button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.connect_without_contact),
                                label: const Text('Connect'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: ftpService.isConnecting
                                    ? null
                                    : () => _connectToServerFromForm(ftpService),
                              ),
                            ),
                            
                            if (ftpService.isConnecting)
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _connectToServerFromForm(FtpService ftpService) {
    if (_formKey.currentState?.validate() ?? false) {
      final connection = FtpConnection(
        name: _nameController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
        isAnonymous: _isAnonymous,
        isPassive: _isPassive,
        timeout: Duration(seconds: _timeoutSeconds),
        secure: _isSecure,
      );
      
      _connectToServer(ftpService, connection);
      
      // Save connection for future use
      _saveConnection(connection);
    }
  }

  void _connectToServer(FtpService ftpService, FtpConnection connection) async {
    try {
      final connected = await ftpService.connect(connection.host,port: connection.port,
        username: connection.username,
        password: connection.password,
      );
      
      if (connected) {
        _showSuccessSnackBar('Connected to ${connection.name}');
        
        // Navigate to the file browser
        if (mounted) {
          final homeState = context.findAncestorStateOfType<HomeScreenState>();
          Navigator.pushReplacementNamed(context, homeState != null ? '/file_browser' : '/connection');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Connection error: ${e.toString()}');
    }
  }

  void _editConnection(FtpConnection connection) {
    // Populate form with connection details
    _nameController.text = connection.name;
    _hostController.text = connection.host;
    _portController.text = connection.port.toString();
    _usernameController.text = connection.username;
    _passwordController.text = connection.password;
    
    setState(() {
      _isAnonymous = connection.isAnonymous;
      _isPassive = connection.isPassive;
      _isSecure = connection.secure;
      _timeoutSeconds = connection.timeout.inSeconds;
    });
  }

  void _confirmDeleteConnection(FtpConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete "${connection.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteConnection(connection);
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

