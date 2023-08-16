export const decodeBase64URI = (uri: string) => {
  let json = JSON.parse(
    Buffer.from(uri.split(',')[1], 'base64').toString('utf-8'),
  );

  const imageAttribute = json.image; // Retrieve the "image" attribute
  const animationUrlAttribute = json.animation_url; // Retrieve the "animation_url" attribute

  // Decode the Base64 data from the "image" attribute
  const imageData = imageAttribute.split(',')[1];
  const decodedImage = Buffer.from(imageData, 'base64').toString('utf-8');

  // Decode the Base64 data from the "animation_url" attribute
  const animationUrlData = animationUrlAttribute.split(',')[1];
  const decodedAnimationUrl = Buffer.from(animationUrlData, 'base64').toString(
    'utf-8',
  );

  // Update the json with the decoded data
  json.image = decodedImage;
  json.animation_url = decodedAnimationUrl;
  return json;
};
