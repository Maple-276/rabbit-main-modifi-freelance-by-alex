import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/response_model.dart';
import 'package:flutter_restaurant/features/auth/domain/models/signup_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/auth/services/auth_service.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Widget that displays the login form with phone input and persuasive UI elements
class LoginFormWidget extends StatefulWidget {
  final AuthService authService;
  final void Function(String?)? onOtpLoginRequested;

  const LoginFormWidget({
    Key? key,
    required this.authService,
    this.onOtpLoginRequested,
  }) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _countryDialCode;
  bool _isLoginMode = true; // Start in login mode
  bool _isButtonDisabled = false; // Track button state

  @override
  void initState() {
    super.initState();
    _countryDialCode = CountryCode.fromCountryCode(Provider.of<SplashProvider>(context, listen: false).configModel!.countryCode!).dialCode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Submits the form for login or registration based on the current mode
  void _submitForm(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isButtonDisabled = true);

      String phoneNumber = '$_countryDialCode${_phoneController.text.trim()}';
      String password = _passwordController.text.trim();

      try {
        ResponseModel responseModel;
        if (_isLoginMode) {
          // Login Logic
          responseModel = await authProvider.login(phoneNumber, password, 'phone');
        } else {
          // Registration Logic - Simplified
          SignUpModel signUpModel = SignUpModel(
            password: password,
            phone: phoneNumber,
          );
          final configModel = Provider.of<SplashProvider>(context, listen: false).configModel;
          if(configModel == null) {
             showCustomSnackBarHelper(getTranslated('configuration_not_loaded', context));
             setState(() => _isButtonDisabled = false);
             return;
          }
          responseModel = await authProvider.registration(signUpModel, configModel);
        }

        // Handle response
        if (responseModel.isSuccess) {
          // Navigate to main screen on successful login/registration
          context.go(RouterHelper.getMainRoute(action: RouteAction.pushReplacement));
          showCustomSnackBarHelper(getTranslated(_isLoginMode ? 'login_successful' : 'registration_successful', context), isError: false);
        } else {
          showCustomSnackBarHelper(responseModel.message);
        }
      } catch (e) {
        showCustomSnackBarHelper(getTranslated('something_went_wrong', context));
        debugPrint('Login/Registration Error: $e');
      } finally {
        // Use mounted check before updating state in async gap
        if (mounted) {
          setState(() => _isButtonDisabled = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Consumer<AuthProvider>(builder: (context, authProvider, child) {
      return Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rabbit logo
              Container(
                height: 120,
                width: 120,
                margin: const EdgeInsets.only(bottom: 15),
                child: CustomAssetImageWidget(
                  Images.logo,
                  fit: BoxFit.contain,
                ),
              ),
              // Persuasive main message
              Text(
                getTranslated('headline_favorites_one_click', context)!,
                style: rubikBold.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Persuasive subtitle
              Text(
                getTranslated('subtitle_enter_number_enjoy', context)!,
                style: rubikRegular.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).hintColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              // Contextual trust text
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        getTranslated('info_only_number_for_updates', context)!,
                        style: rubikRegular.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Phone Number Field (Common to both modes)
              CustomTextFieldWidget(
                hintText: getTranslated('enter_phone_number', context),
                controller: _phoneController,
                inputType: TextInputType.phone,
                countryDialCode: _countryDialCode,
                onCountryChanged: (CountryCode code) {
                  setState(() {
                    _countryDialCode = code.dialCode;
                  });
                },
                onValidate: (value) {
                  if (value == null || value.isEmpty) {
                    return getTranslated('enter_phone_number', context);
                  } else if (!RegExp(r'^[0-9]{8,15}$').hasMatch(value)) {
                    return getTranslated('enter_valid_phone_number', context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              // Password Field (Common to both modes)
              CustomTextFieldWidget(
                hintText: getTranslated('password', context),
                controller: _passwordController,
                inputType: TextInputType.visiblePassword,
                isPassword: true,
                isShowSuffixIcon: true,
                prefixIconData: Icons.lock_outline,
                inputAction: TextInputAction.done,
                onValidate: (value) {
                  if (value == null || value.isEmpty) {
                    return getTranslated('enter_password', context);
                  } else if (value.length < 6) {
                    return getTranslated('password_should_be', context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              // Submit Button
              !authProvider.isLoading
                  ? CustomButtonWidget(
                      isLoading: _isButtonDisabled,
                      btnTxt: _isLoginMode
                        ? getTranslated('login', context)
                        : getTranslated('register', context),
                      onTap: _isButtonDisabled ? null : () => _submitForm(authProvider),
                    )
                  : const Center(child: CircularProgressIndicator()),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Login with OTP button - Styled as CustomButtonWidget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge * 2), // Add horizontal padding to shorten the button
                child: CustomButtonWidget(
                  btnTxt: getTranslated('login_with_otp', context),
                  textStyle: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                  backgroundColor: Colors.transparent,
                  onTap: () {
                    // Call the callback passed from LoginScreen
                    widget.onOtpLoginRequested?.call(_phoneController.text);
                  },
                ),
              ),
              if(widget.onOtpLoginRequested != null) const SizedBox(height: Dimensions.paddingSizeDefault),

              // Toggle between Login and Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    getTranslated(_isLoginMode ? 'dont_have_account' : 'already_have_account', context)!,
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        // Optionally clear fields when switching modes
                        _phoneController.clear(); // Keep phone?
                        _passwordController.clear();
                      });
                    },
                    child: Text(
                      getTranslated(_isLoginMode ? 'signup' : 'login', context)!,
                      style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Social proof element
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      getTranslated('social_proof_join_users', context)!,
                      style: rubikMedium.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // Terms and privacy policy text
              Text(
                getTranslated('legal_terms_privacy', context)!,
                style: rubikRegular.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              // Cancel button (if applicable)
              if (Navigator.canPop(context)) _buildCancelButton(),
              // Guest login button
              const SizedBox(height: 15),
              _buildGuestLoginButton(),
            ],
          ),
        ),
      );
    });
  }

  /// Builds the cancel button
  Widget _buildCancelButton() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          getTranslated('cancel', context)!,
          style: rubikMedium.copyWith(
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Builds the guest login button
  Widget _buildGuestLoginButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          try {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            RouterHelper.getDashboardRoute(
              'home',
              action: RouteAction.pushNamedAndRemoveUntil,
            );
          } catch (e) {
            debugPrint('Error de navegación: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(getTranslated('navigation_error', context) ?? 'Error de navegación'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.person_outline, size: 18),
        label: Text(
          getTranslated('enter_as_guest', context)!,
          style: rubikMedium.copyWith(
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}