import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/extensions/string.dart';
import 'package:fuodz/models/vehicle.dart';
import 'package:fuodz/requests/auth.request.dart';
import 'package:fuodz/requests/general.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/phone_util.service.dart';
import 'package:fuodz/traits/qrcode_scanner.trait.dart';
import 'package:fuodz/widgets/bottomsheets/account_verification_entry.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'base.view_model.dart';

class RegisterViewModel extends MyBaseViewModel with QrcodeScannerTrait {
  //the textediting controllers
  TextEditingController carMakeTEC = new TextEditingController();
  TextEditingController carModelTEC = new TextEditingController();
  List<String> types = ["Regular", "Taxi"];
  List<VehicleType> vehicleTypes = [];
  String selectedDriverType = "regular";
  List<CarMake> carMakes = [];
  List<CarModel> carModels = [];
  CarMake? selectedCarMake;
  CarModel? selectedCarModel;
  List<File> selectedDocuments = [];
  bool hidePassword = true;
  late Country selectedCountry;

  //
  AuthRequest _authRequest = AuthRequest();
  GeneralRequest _generalRequest = GeneralRequest();

  RegisterViewModel(BuildContext context) {
    this.viewContext = context;
    final countryCoe = PhoneUtilService.countryCode ?? "us";
    this.selectedCountry = Country.parse(countryCoe);
  }

  @override
  void initialise() {
    super.initialise();
    fetchVehicleTypes();
    fetchCarMakes();
  }

  showCountryDialPicker() {
    showCountryPicker(
      context: viewContext,
      showPhoneCode: true,
      onSelect: (value) => countryCodeSelected(value),
    );
  }

  countryCodeSelected(Country country) {
    selectedCountry = country;
    notifyListeners();
  }

  void onDocumentsSelected(List<File> documents) {
    selectedDocuments = documents;
    notifyListeners();
  }

  void onSelectedDriverType(String? value) {
    selectedDriverType = value ?? "regular";
    notifyListeners();
  }

  onCarMakeSelected(dynamic value) {
    if (!(value is CarMake)) {
      value = carMakes.firstWhere((carMake) => carMake.id == value);
    }
    selectedCarMake = value;
    carMakeTEC.text = value.name;
    notifyListeners();
    fetchCarModel();
  }

  onCarModelSelected(dynamic value) {
    if (!(value is CarModel)) {
      value = carModels.firstWhere((carModel) => carModel.id == value);
    }
    selectedCarModel = value;
    carModelTEC.text = value.name;
    notifyListeners();
  }

  void fetchVehicleTypes() async {
    setBusyForObject(vehicleTypes, true);
    try {
      vehicleTypes = await _generalRequest.getVehicleTypes();
    } catch (error) {
      toastError("$error");
    }
    setBusyForObject(vehicleTypes, false);
  }

  void fetchCarMakes() async {
    setBusyForObject(carMakes, true);
    try {
      carMakes = await _generalRequest.getCarMakes();
    } catch (error) {
      toastError("$error");
    }
    setBusyForObject(carMakes, false);
  }

  void fetchCarModel() async {
    setBusyForObject(carModels, true);
    try {
      carModels = await _generalRequest.getCarModels(
        carMakeId: selectedCarMake?.id,
      );
    } catch (error) {
      toastError("$error");
    }
    setBusyForObject(carModels, false);
  }

  // Phone-first (Firebase OTP) state.
  String? accountPhoneNumber;
  String? _firebaseIdToken;
  Map<String, dynamic>? _pendingParams;

  void processRegister() async {
    // Validate returns true if the form is valid, otherwise false.
    if (formBuilderKey.currentState!.saveAndValidate()) {
      Map<String, dynamic> mValues = formBuilderKey.currentState!.value;
      final carData = {
        "car_make_id": selectedCarMake?.id,
        "car_model_id": selectedCarModel?.id,
      };

      final values = {...mValues, ...carData};
      Map<String, dynamic> params = Map.from(values);
      String phone = params['phone'].toString().telFormat();
      params["phone"] = "+${selectedCountry.phoneCode}${phone}";
      accountPhoneNumber = params["phone"];

      // Phone-first: verify the number with Firebase OTP before registering.
      // Drivers must verify their phone; the account then lands PENDING review.
      if (AppStrings.isFirebaseOtp) {
        _pendingParams = params;
        processFirebaseOTPVerification();
      } else {
        await _submitRegistration(params);
      }
    }
  }

  // Send the OTP via Firebase for the entered phone number.
  processFirebaseOTPVerification() async {
    setBusy(true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: accountPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-retrieval: sign in and submit straight away.
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          _firebaseIdToken = await userCredential.user?.getIdToken();
        } catch (_) {}
        setBusy(false);
        await _submitRegistration(_pendingParams!, idToken: _firebaseIdToken);
      },
      verificationFailed: (FirebaseAuthException e) {
        setBusy(false);
        final msg = e.code == 'invalid-phone-number'
            ? "Invalid Phone Number".tr()
            : (e.message ?? "Error".tr());
        AlertService.error(title: "Become a partner".tr(), text: msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        firebaseVerificationId = verificationId;
        setBusy(false);
        showVerificationEntry();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Bottom sheet for manual SMS-code entry.
  void showVerificationEntry() {
    Navigator.of(viewContext).push(
      MaterialPageRoute(
        builder: (context) => AccountVerificationEntry(
          vm: this,
          phone: accountPhoneNumber ?? "",
          onSubmit: (smsCode) {
            Navigator.of(viewContext).pop();
            verifyFirebaseOTP(smsCode);
          },
        ),
      ),
    );
  }

  void verifyFirebaseOTP(String smsCode) async {
    setBusy(true);
    try {
      final phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: firebaseVerificationId!,
        smsCode: smsCode,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
      _firebaseIdToken = await userCredential.user?.getIdToken();
      await _submitRegistration(_pendingParams!, idToken: _firebaseIdToken);
    } catch (error) {
      setBusy(false);
      toastError("$error");
    }
  }

  // Submit the registration to /driver/register, attaching the verified token.
  Future<void> _submitRegistration(
    Map<String, dynamic> params, {
    String? idToken,
  }) async {
    setBusy(true);
    try {
      if (idToken != null && idToken.isNotEmpty) {
        params["firebase_id_token"] = idToken;
      }
      final apiResponse = await _authRequest.registerRequest(
        vals: params,
        docs: selectedDocuments,
      );

      if (apiResponse.allGood) {
        await AlertService.success(
          title: "Become a partner".tr(),
          text: "${apiResponse.message}",
        );
      } else {
        toastError("${apiResponse.message}");
      }
    } catch (error) {
      toastError("$error");
    }
    setBusy(false);
  }
}
