import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fuodz/constants/app_images.dart';
import 'package:fuodz/view_models/profile.vm.dart';
import 'package:fuodz/views/pages/profile/manage_account.page.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:fuodz/widgets/states/custom_loading.state.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard(this.model, {Key? key}) : super(key: key);

  final ProfileViewModel model;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: VStack([
        //profile card
        CustomLoadingStateView(
          loading: model.isBusy,
          child: HStack([
            //
            CachedNetworkImage(
              imageUrl: model.currentUser.photo,
              progressIndicatorBuilder: (context, imageUrl, progress) {
                return BusyIndicator();
              },
              errorWidget: (context, imageUrl, progress) {
                return Image.asset(AppImages.user);
              },
            ).wh(Vx.dp64, Vx.dp64).box.roundedFull.clip(Clip.antiAlias).make(),

            //
            VStack([
              "${model.currentUser.name}".text.xl.semiBold.make(),
              "${model.currentUser.email}".text.light.make(),
            ]).px20().expand(),

            //arrow icon
            HugeIcon(icon: HugeIcons.strokeRoundedEdit02,
              size: 24,
              color: context.primaryColor,
            ),
          ]).p12().onTap(() {
            context.nextPage(ManageAccountPage());
          }),
        ),
      ]).wFull(context),
    );
  }
}
