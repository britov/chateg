import 'package:chateg/models.dart';
import 'package:chateg/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeDrawer extends StatefulWidget {
  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Selector<UserModel, String>(
            selector: (_, model) => model.name,
            builder: (context, name, _) {
              return Expanded(
                child: ListView(
                  children: <Widget>[
                    DrawerHeader(
                      decoration: BoxDecoration(
                          color: Colors.lightGreen
                      ),
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            bottom: 10,
                            left: 0,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.perm_identity),
                                Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(name?.isNotEmpty == true ? name : 'No name :(')
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Change name'),
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(Routes.username, (_) => false);
                        return context.read<UserModel>().name = null;
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Change server'),
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(Routes.server, (_) => false);
                        return context.read<UserModel>().serverName = null;
                      },
                    )
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
