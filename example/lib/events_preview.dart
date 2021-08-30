import 'package:fairbid_flutter/fairbid_flutter.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

showEventsStream(
        {required BuildContext context,
        required Stream<AdEventType> events,
        required String placement}) =>
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              child: Text(
                "Events: $placement",
                style: Theme.of(context).textTheme.headline4,
              ),
              padding: EdgeInsets.all(8),
            ),
            Divider(),
            StreamBuilder<List<MapEntry<AdEventType, DateTime>>>(
              initialData: [],
              stream: events.map((event) => MapEntry(event, DateTime.now())).scan((l, event, _) {
                final list = l ?? [];
                if (list.length == 5) {
                  list.removeLast();
                }
                list.insert(0, event);
                return list;
              }, []),
              builder: (c, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!
                    .map((eventType) => Padding(
                          child: Text(
                              "${eventType.value}: ${eventType.key.toString().split('.').last}"),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ))
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
