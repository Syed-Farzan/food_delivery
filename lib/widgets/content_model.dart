class UnboardingContent {
  String image;
  String title;
  String descryption;
  UnboardingContent({
    required this.descryption,
    required this.image,
    required this.title,
  });
}

List<UnboardingContent> contents = [
  UnboardingContent(
    descryption: 'Pick your food from our menu\n     more than 35 times',
    image: 'lib/images/screen1.png',
    title: 'Select from Our\n Best Products',
  ),
  UnboardingContent(
    descryption: 'You can pay online\n',
    image: 'lib/images/screen2.png',
    title: 'Easy And Online Payment',
  ),
  UnboardingContent(
    descryption: 'Deliver your product at your\n   Doorstep',
    image: 'lib/images/screen3.png',
    title: 'Quick Delivery at your Doorstep',
  ),
];
