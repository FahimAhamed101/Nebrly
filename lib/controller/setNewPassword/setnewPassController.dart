
import 'package:get/get.dart';

class SetNewPasswordController extends GetxController{
 RxBool showhide = false.obs;
 RxBool showhideConfirm = false.obs;
 void passwordToggle(){
   showhide.value =! showhide.value;
 }
 void confirmPasswordToggle(){
   showhideConfirm.value =! showhideConfirm.value;
 }
}