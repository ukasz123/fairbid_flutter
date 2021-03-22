import 'package:flutter/material.dart';
import 'package:fairbid_flutter/fairbid_flutter.dart';

class UserDataForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserData>(
      builder: (BuildContext context, AsyncSnapshot<UserData> snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          return new _UserDataFormFields(data: data);
        } else {
          return Container();
        }
      },
      future: UserData.getCurrent(),
    );
  }
}

class _UserDataFormFields extends StatefulWidget {
  const _UserDataFormFields({
    Key? key,
    required this.data,
  }) : super(key: key);

  final UserData data;

  @override
  __UserDataFormFieldsState createState() => __UserDataFormFieldsState();
}

class __UserDataFormFieldsState extends State<_UserDataFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButton<Gender>(
          hint: Text("Gender"),
          value: widget.data.gender,
          items: Gender.values
              .map((gender) => DropdownMenuItem<Gender>(
                    value: gender,
                    child: Text("${gender.toString().split('.').last}"),
                  ))
              .toList(),
          onChanged: (gender) => setState(() {
            widget.data.gender = gender!;
          }),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: TextFormField(
                initialValue: "${widget.data.location?.latitude}",
                decoration: InputDecoration(labelText: "Location", hintText: 'Latitude'),
              ),
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: TextFormField(
                initialValue: "${widget.data.location?.longitude}",
                decoration: InputDecoration(labelText: "", hintText: 'Longitude'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
