import 'package:fairbid_flutter/fairbid_flutter.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

showEventsStream(
        {BuildContext context, Stream<AdEventType> events, String placement}) =>
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
                style: Theme.of(context).textTheme.display1,
              ),
              padding: EdgeInsets.all(8),
            ),
            Divider(),
            StreamBuilder<List<MapEntry<AdEventType, DateTime>>>(
              initialData: [],
              stream: Observable(events)
                  .map((event) => MapEntry(event, DateTime.now()))
                  .scan((list, event, _) {
                if (list.length == 5) {
                  list.removeLast();
                }
                list.insert(0, event);
                return list;
              }, []),
              builder: (c, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data
                    .map((eventType) => Padding(
                          child: Text(
                              "${eventType.value}: ${eventType.key.toString().split('.').last}"),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ))
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
