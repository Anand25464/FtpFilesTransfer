import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ftp_service.dart';
import '../models/ftp_server.dart';
import 'server_connection_screen.dart';
import 'file_browser_screen.dart';
import '../widgets/connection_status_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<FtpServer> _savedServers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedServers();
  }


  // In a real app, you would load from persistent storage
  Future<void> _loadSavedServers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
      // For now, we'll just add some sample servers for demonstration
      // In a real app, you would load from shared preferences or a database
    });
  }

  void _addNewServer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServerConnectionScreen(),
      ),
    );

    if (result != null && result is FtpServer) {
      setState(() {
        _savedServers.add(result);
      });
    }
  }

  void _connectToServer(FtpServer server) async {
    final ftpService = Provider.of<FtpService>(context, listen: false);
    
    try {
      bool connected = await ftpService.connect(
        server.host,
        port:server.port,
        username:server.username,
        password:server.password,
      );
      
      if (connected && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileBrowserScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT FTP Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadSavedServers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ConnectionStatusWidget(),
                Expanded(
                  child: _savedServers.isEmpty
                      ? _buildEmptyState()
                      : _buildServerList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewServer,
        tooltip: 'Add FTP Server',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.devices_other,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No IoT FTP Servers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a new FTP server to connect to your IoT device',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add FTP Server'),
            onPressed: _addNewServer,
          ),
        ],
      ),
    );
  }

  Widget _buildServerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedServers.length,
      itemBuilder: (context, index) {
        final server = _savedServers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.devices, color: Colors.blue),
            title: Text(server.name),
            subtitle: Text('${server.host}:${server.port}'),
            trailing: IconButton(
              icon: const Icon(Icons.connect_without_contact),
              onPressed: () => _connectToServer(server),
            ),
            onTap: () => _connectToServer(server),
          ),
        );
      },
    );
  }
}
