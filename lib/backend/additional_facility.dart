import 'package:diamond_host_admin/backend/rooms.dart';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../localization/language_constants.dart';
import '../screens/date_hotel_booking_screen.dart';
import '../widgets/text_form_field_stile.dart';
import 'add_image.dart';
import 'additional.dart';

class AdditionalFacility extends StatefulWidget {
  final String CheckState;
  final String IDEstate;
  final String estate;
  final bool CheckIsBooking;
  final List<Rooms>? Lstroom;

  AdditionalFacility({
    required this.CheckState,
    required this.CheckIsBooking,
    required this.estate,
    required this.IDEstate,
    this.Lstroom,
  });

  @override
  _State createState() =>
      _State(CheckState, CheckIsBooking, IDEstate, Lstroom, estate);
}

class _State extends State<AdditionalFacility> {
  final GlobalKey<ScaffoldState> _scaffoldKey1 = new GlobalKey<ScaffoldState>();
  final String CheckState;
  final bool CheckIsBooking;
  final String IDEstate;
  final List<Rooms>? Lstroom;
  final String estate; // estate as String

  DatabaseReference ref =
      FirebaseDatabase.instance.ref("App").child("Fasilty ");
  List<Additional> LstAdditional = [];
  List<Additional> LstAdditionalTmp = [];
  List<Additional> LstAdditionalSelected = [];

  TextEditingController EnName_Controller = TextEditingController();
  TextEditingController Name_Controller = TextEditingController();
  TextEditingController Price_Controller = TextEditingController();
  int i = 0;

  _State(this.CheckState, this.CheckIsBooking, this.IDEstate, this.Lstroom,
      this.estate);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey1,
        appBar: AppBar(
          iconTheme: kIconTheme,
        ),
        body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 30, left: 15, right: 15),
                  child: Text(
                    getTranslated(context, "additional services"),
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  child: CheckIsBooking
                      ? SizedBox(
                          child: FirebaseAnimatedList(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            defaultChild: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            itemBuilder: (context, snapshot, animation, index) {
                              Map map = snapshot.value as Map;
                              map['Key'] = snapshot.key;
                              if (map['Name'].toString().toLowerCase() !=
                                  "name") {
                                LstAdditionalTmp.add(Additional(
                                    id: map['ID'],
                                    name: map['Name'],
                                    price: map['Price'],
                                    nameEn: map['Name'],
                                    isBool: false,
                                    color: Colors.white));
                                return Container(
                                  height: 70,
                                  color: LstAdditionalTmp[index].color,
                                  margin: const EdgeInsets.all(15),
                                  child: ListTile(
                                    onTap: () {
                                      int indx =
                                          LstAdditionalSelected.indexWhere(
                                              (element) =>
                                                  element.id == map['ID']);

                                      if (indx == -1) {
                                        LstAdditionalSelected.add(Additional(
                                            id: map['ID'],
                                            name: map['Name'],
                                            price: map['Price'],
                                            nameEn: map['NameEn'],
                                            isBool: false,
                                            color: Colors.white));
                                        setState(() {
                                          LstAdditionalTmp[index].color =
                                              Colors.amberAccent;
                                        });
                                      } else {
                                        LstAdditionalSelected.removeAt(indx);
                                        setState(() {
                                          LstAdditionalTmp[index].color =
                                              Colors.white;
                                        });
                                      }
                                    },
                                    title: Text(LstAdditionalTmp[index].name),
                                    subtitle:
                                        Text(LstAdditionalTmp[index].price),
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                            query: FirebaseDatabase.instance
                                .ref("App")
                                .child("Fasilty ")
                                .child(IDEstate),
                          ),
                        )
                      : CheckState == "add"
                          ? PageAdd()
                          : PageUpdate(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: Container(
                      width: 150.w,
                      height: 6.h,
                      margin: const EdgeInsets.only(
                          right: 40, left: 40, bottom: 20),
                      decoration: BoxDecoration(
                        color: kDeepPurpleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          getTranslated(context, "Next"),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    onTap: () async {
                      if (CheckIsBooking) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => DateBooking(
                                  Estate: estate,
                                  LstAdditional: LstAdditionalSelected,
                                  LstRooms: Lstroom!,
                                  estateID: IDEstate,
                                )));
                      } else {
                        if (CheckState == "Edit") {
                          await ref.child(IDEstate).remove();
                          for (int i = 0; LstAdditional.length > 0; i++) {
                            if (LstAdditional[i].isBool) {
                              // false update
                            }
                          }
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AddImage(
                                    IDEstate: IDEstate,
                                  )));
                        } else {
                          Additional additional = new Additional(
                              id: "",
                              name: "Name",
                              nameEn: "NameEn",
                              price: "Price",
                              isBool: false,
                              color: Colors.white);
                          Save(additional);

                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AddImage(
                                    IDEstate: IDEstate,
                                  )));
                        }
                      }
                    },
                  ),
                ),
              ],
            )));
  }

  Element(Additional obj) {
    return Card(
      child: ListTile(
        title: Text(obj.name),
        subtitle: Text(obj.price),
        trailing: Checkbox(
          checkColor: Colors.white,
          value: obj.isBool,
          onChanged: (bool? value) {
            setState(() {
              obj.isBool = value!;
            });
          },
        ),
      ),
      elevation: 5,
    );
  }

  PageAdd() {
    return Container(
      child: Wrap(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "Name",
                icon: Icon(
                  Icons.person,
                  color: kDeepPurpleColor,
                ),
                control: Name_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "NameEN",
                icon: Icon(
                  Icons.person,
                  color: kDeepPurpleColor,
                ),
                control: EnName_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: TextFormFieldStyle(
                      context: context,
                      hint: "Price",
                      icon: Icon(
                        Icons.person,
                        color: kDeepPurpleColor,
                      ),
                      control: Price_Controller,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.number),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: Container(
                      height: 6.5.h,
                      width: 150.w,
                      margin: const EdgeInsets.only(right: 40, top: 10),
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          getTranslated(context, "Save"),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    onTap: () async {
                      i++;
                      Additional x = new Additional(
                          id: i.toString(),
                          name: Name_Controller.text,
                          price: Price_Controller.text,
                          nameEn: EnName_Controller.text,
                          isBool: false,
                          color: Colors.white);
                      setState(() {
                        LstAdditionalTmp.add(x);
                      });
                      Save(x);
                    },
                  ),
                ),
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.only(
              bottom: 20,
            ),
            child: ListView.builder(
                itemCount: LstAdditionalTmp.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    child: ListTile(title: Text(LstAdditionalTmp[index].name)),
                  );
                }),
            height: 250,
          ),
        ],
      ),
    );
  }

  PageUpdate() {
    return Container(
      child: Wrap(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "Name",
                icon: Icon(
                  Icons.person,
                  color: kDeepPurpleColor,
                ),
                control: Name_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: TextFormFieldStyle(
                context: context,
                hint: "NameEN",
                icon: Icon(
                  Icons.person,
                  color: kDeepPurpleColor,
                ),
                control: EnName_Controller,
                isObsecured: false,
                validate: true,
                textInputType: TextInputType.text),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: TextFormFieldStyle(
                      context: context,
                      hint: "Price",
                      icon: Icon(
                        Icons.person,
                        color: kDeepPurpleColor,
                      ),
                      control: Price_Controller,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.number),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: Container(
                      height: 6.5.h,
                      width: 150.w,
                      margin: const EdgeInsets.only(right: 40, top: 10),
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: kDeepPurpleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(getTranslated(context, "Save")),
                      ),
                    ),
                    onTap: () async {
                      i++;
                      Additional x = new Additional(
                          id: i.toString(),
                          name: Name_Controller.text,
                          price: Price_Controller.text,
                          nameEn: EnName_Controller.text,
                          isBool: false,
                          color: Colors.white);
                      setState(() {
                        LstAdditionalTmp.add(x);
                      });
                      SaveUpdate(x);
                    },
                  ),
                ),
              )
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 40, top: 10),
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: FirebaseAnimatedList(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              defaultChild: const Center(
                child: CircularProgressIndicator(),
              ),
              itemBuilder: (context, snapshot, animation, index) {
                Map map = snapshot.value as Map;
                map['Key'] = snapshot.key;
                LstAdditionalTmp.add(Additional(
                    id: map['ID'],
                    name: map['Name'],
                    price: map['Price'],
                    nameEn: "",
                    isBool: false,
                    color: Colors.white));
                return Container(
                  height: 50,
                  child: ListTile(
                    title: Text(map['Name']),
                    subtitle: Text(map['Price']),
                    onTap: () {
                      setState(() {
                        Name_Controller.text = map['Name'];
                        EnName_Controller.text = map['NameEn'];
                        Price_Controller.text = map['Price'];
                      });
                    },
                  ),
                );
              },
              query: FirebaseDatabase.instance
                  .ref("App")
                  .child("Fasilty ")
                  .child(IDEstate),
            ),
          )
        ],
      ),
    );
  }

  Save(Additional obj) async {
    if (obj.nameEn.toLowerCase() != "NameEn".toLowerCase()) {
      await ref.child(IDEstate).child(obj.name).set({
        "ID": obj.id,
        "Name": obj.name,
        "NameEn": obj.nameEn,
        "Price": obj.price,
      });
    }

    setState(() {
      Name_Controller.text = "";
      EnName_Controller.text = "";
      Price_Controller.text = "";
    });
  }

  SaveUpdate(Additional obj) async {
    ref.child(IDEstate).child(obj.name).remove();
    await ref.child(IDEstate).child(obj.name).set({
      "ID": obj.id,
      "Name": obj.name,
      "NameEn": obj.nameEn,
      "Price": obj.price,
    });
  }
}
