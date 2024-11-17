import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:weather_app/week_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;
  List<dynamic>? hourlyTimes;
  List<dynamic>? hourlyTemperatures;
  List<dynamic>? hourlyHumidities;
  String? timezone;
  String? greeting;
  String? formattedDate;
  String? formattedTime;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    await getCurrentLocation();
    await fetchData();
  }

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log("Location permission denied. Requesting permission...");
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        log("Latitude: ${currentPosition.latitude}, Longitude: ${currentPosition.longitude}");
      } else {
        log("Location permission not granted.");
      }
    } catch (e) {
      log("Error getting location: $e");
    }
  }

  Future<void> fetchData() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      Uri url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${currentPosition.latitude}&longitude=${currentPosition.longitude}&current=temperature_2m,relative_humidity_2m&hourly=temperature_2m,relative_humidity_2m',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          hourlyTimes = data!['hourly']['time'].sublist(0, 24);
          hourlyTemperatures = data!['hourly']['temperature_2m'].sublist(0, 24);
          hourlyHumidities =
              data!['hourly']['relative_humidity_2m'].sublist(0, 24);
          timezone = data!['timezone'];

          DateTime currentTime = DateTime.now();
          int currentHour = currentTime.hour;
          greeting = currentHour < 12
              ? 'Good Morning'
              : (currentHour < 17 ? 'Good Afternoon' : 'Good Evening');
          formattedDate = DateFormat('EEEE, d').format(currentTime);
          formattedTime = DateFormat('h:mm a').format(currentTime);
        });
      } else {
        log("Error fetching weather data: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching data: $e");
    }
  }

  Widget gradientText(String text, double fontSize, FontWeight fontWeight) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFA500), Color(0xFFFFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.openSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: data == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFA500),
              const Color(0xFF8A2BE2).withOpacity(0.6),
              const Color(0xFF000000).withOpacity(0.9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 60,
            bottom: 40,
            right: 24,
            left: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.openSans(height: 1.1),
                      children: <TextSpan>[
                        TextSpan(
                          text: "$timezone\n",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w100,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        TextSpan(
                          text: "$greeting",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WeekScreen()));
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          width: 0.4,
                          color: Colors.white,
                        ),
                      ),
                      child: const Icon(
                        Icons.more_vert_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/image.png"),
                      opacity: 0.7,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.openSans(height: 1.2),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                        "${data!["current"]["temperature_2m"].toString().substring(0, 2)}°C\n",
                        style: const TextStyle(
                          fontSize: 74,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text:
                        "Humidity ${data!["current"]["relative_humidity_2m"]}%\n",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: "$formattedDate , $formattedTime",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(0),
                  itemCount: hourlyTimes?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Container(
                      padding:
                      const EdgeInsets.only(bottom: 12, top: 5),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat("h a").format(
                              DateTime.parse(
                                hourlyTimes![index],
                              ),
                            ),
                            style: GoogleFonts.openSans(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Humidity",
                                style: GoogleFonts.openSans(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                "${hourlyHumidities![index]}%",
                                style: GoogleFonts.openSans(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${hourlyTemperatures![index].toString().substring(0, 2)}°C",
                            style: GoogleFonts.openSans(
                              fontSize: 50,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
