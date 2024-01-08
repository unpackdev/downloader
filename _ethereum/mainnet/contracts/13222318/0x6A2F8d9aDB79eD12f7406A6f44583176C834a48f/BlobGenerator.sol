//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Color.sol";
import "./Base64.sol";
import "./PRBMathSD59x18.sol";

contract BlobGenerator {
  constructor() {}

  using PRBMathSD59x18 for int256;

  struct Points {
    int256 x;
    int256 y;
  }

  function uintToStr(uint256 v) private pure returns (string memory) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;

    if (v == 0) {
      return "0";
    }

    while (v != 0) {
      uint256 remainder = v % 10;
      v = v / 10;
      reversed[i % maxlength] = bytes1(uint8(48 + remainder));
      i++;
    }
    bytes memory s = new bytes(i);
    for (uint256 j = 1; j <= i % maxlength; j++) {
      s[j - 1] = reversed[i - j];
    }
    return string(s);
  }

  function intToStr(int256 v) private pure returns (string memory) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    uint256 x;

    if (v == 0) {
      return "0";
    }

    if (v < 0) x = uint256(-v);
    else x = uint256(v);
    while (x != 0) {
      uint256 remainder = uint256(x % 10);
      x = x / 10;
      reversed[i % maxlength] = bytes1(uint8(48 + remainder));
      i++;
    }
    if (v < 0) reversed[(i++) % maxlength] = "-";
    bytes memory s = new bytes(i);
    for (uint256 j = 1; j <= i % maxlength; j++) {
      s[j - 1] = reversed[i - j];
    }
    return string(s);
  }

  function fromInt(int256 original) private pure returns (int256) {
    return PRBMathSD59x18.fromInt(original);
  }

  function fromUInt(uint256 original) private pure returns (int256) {
    return fromInt(int256(original));
  }

  function pi() internal pure returns (int256) {
    return PRBMathSD59x18.pi();
  }

  function generateZeroPad(uint256 size) private pure returns (string memory) {
    bytes memory padding = new bytes(size);

    for (uint256 i = 0; i < size; i++) {
      padding[i] = "0";
    }

    return string(padding);
  }

  function padFraction(int256 fraction) private pure returns (string memory) {
    bytes memory fractionString = bytes(abi.encodePacked(intToStr(fraction)));

    uint256 padSize = 18 - fractionString.length;
    string memory paddedFraction = concatToString(
      generateZeroPad(padSize),
      string(fractionString)
    );

    return paddedFraction;
  }

  function toPrecision(string memory fraction, uint256 precision)
    private
    pure
    returns (string memory)
  {
    bytes memory fractionBytes = bytes(fraction);
    bytes memory result = new bytes(precision);
    for (uint256 i = 0; i < precision; i++) {
      result[i] = fractionBytes[0];
    }

    return string(abi.encodePacked(".", string(result)));
  }

  function toDecimalString(int256 fixedInt, uint256 precision)
    private
    pure
    returns (string memory)
  {
    int256 fraction = fixedInt.frac();
    int256 exponent = fixedInt.toInt();
    string memory expStr = intToStr(exponent);
    if (fixedInt < 0) {
      fraction = fraction.mul(fromInt(-1));
      if (exponent == 0) {
        expStr = "-";
      }
    }

    string memory paddedFraction = padFraction(fraction);
    return
      string(abi.encodePacked(expStr, toPrecision(paddedFraction, precision)));
  }

  function toDecimalString(int256 exponent)
    private
    pure
    returns (string memory)
  {
    return toDecimalString(exponent, 3);
  }

  function getSeed(string memory feature, uint256 tokenId)
    private
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(feature, tokenId)));
  }

  function random(
    uint256 seed,
    uint256 start,
    uint256 end
  ) private pure returns (uint256) {
    return (seed % (end - start + 1)) + start;
  }

  function concatToString(string memory A, string memory B)
    private
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(A, B));
  }

  function sin(int256 degrees) private pure returns (int256) {
    int256 x = degrees % fromInt(180);
    int256 dividend = fromInt(4).mul(x).mul(fromInt(180) - x);
    int256 divisor = fromInt(40500) - x.mul(fromInt(180) - x);

    int256 result = dividend.div(divisor);
    return degrees > fromInt(180) ? result.mul(fromInt(-1)) : result;
  }

  function cos(int256 degrees) private pure returns (int256) {
    return sin(degrees - fromInt(90));
  }

  function addToIArray(int256[] memory original, int256 newItem)
    private
    pure
    returns (int256[] memory)
  {
    int256[] memory newArray = new int256[](original.length + 1);

    for (uint256 i = 0; i < original.length; i++) {
      newArray[i] = original[i];
    }

    newArray[original.length] = newItem;

    return newArray;
  }

  //pull should be in 59.18 int
  function createPoints(
    string memory prefix,
    uint256 tokenId,
    uint256 numPoints,
    uint256 radius
  ) private pure returns (Points[] memory) {
    Points[] memory pointsArr = new Points[](numPoints);

    int256 angleStep = fromInt(360).div(fromUInt(numPoints));
    // console.log("rad step",toDecimalString(angleStep));
    for (uint256 i = 1; i <= numPoints; i++) {
      //random pull;
      int256 pull = fromUInt(
        random(
          getSeed(
            string(abi.encodePacked(prefix, "PULL", uintToStr(i))),
            tokenId
          ),
          5,
          15
        )
      ).div(fromInt(10));

      int256 x = fromInt(200) +
        cos(fromUInt(i).mul(angleStep)).mul(fromUInt(radius).mul(pull));
      int256 y = fromInt(200) +
        sin(fromUInt(i).mul(angleStep)).mul(fromUInt(radius).mul(pull));

      pointsArr[i - 1] = Points(x, y);
    }

    return pointsArr;
  }

  function loopPoints(Points[] memory pointsArr)
    private
    pure
    returns (Points[] memory)
  {
    Points memory lastPoint = pointsArr[pointsArr.length - 1];
    Points memory secondToLastPoint = pointsArr[pointsArr.length - 2];

    Points memory firstPoint = pointsArr[0];
    Points memory secondPoint = pointsArr[1];

    Points[] memory loopedPoints = new Points[](pointsArr.length + 4);

    // console.log("loopedPoints");
    loopedPoints[0] = secondToLastPoint;
    loopedPoints[1] = lastPoint;
    // console.log(toDecimalString(loopedPoints[0].x),toDecimalString(loopedPoints[0].y));
    // onsole.log(toDecimalString(loopedPoints[1].x),toDecimalString(loopedPoints[1].y));

    //TODO missing points
    for (uint256 i = 0; i < pointsArr.length; i++) {
      loopedPoints[i + 2] = pointsArr[i];
      // console.log(toDecimalString(loopedPoints[i+2].x),toDecimalString(loopedPoints[i+2].y));
    }

    loopedPoints[loopedPoints.length - 2] = firstPoint;
    loopedPoints[loopedPoints.length - 1] = secondPoint;
    // console.log(toDecimalString(loopedPoints[loopedPoints.length - 2].x),toDecimalString(loopedPoints[loopedPoints.length - 2].y));
    // console.log(toDecimalString(loopedPoints[loopedPoints.length - 1].x),toDecimalString(loopedPoints[loopedPoints.length - 1].y));

    return loopedPoints;
  }

  function concatStringArray(string[] memory stringArr)
    private
    pure
    returns (string memory)
  {
    string memory result = stringArr[0];

    for (uint256 i = 1; i < stringArr.length; i++) {
      result = string(abi.encodePacked(result, stringArr[i]));
    }

    return result;
  }

  function generateCPath(
    Points[] memory pointsArr,
    uint256 startIteration,
    uint256 maxIteration,
    uint256 tension
  ) private pure returns (string memory) {
    Points[] memory cPathPoints = new Points[](2);
    string[] memory pathParts = new string[](12);
    string memory cPathString = "";

    for (uint256 i = startIteration; i < maxIteration; i++) {
      //TODO BUGGED
      Points memory p0 = i > 0 ? pointsArr[i - startIteration] : pointsArr[0];
      Points memory p1 = pointsArr[i];
      Points memory p2 = pointsArr[i + 1];
      Points memory p3 = i != maxIteration ? pointsArr[i + 2] : p2;

      cPathPoints[0].x =
        p1.x +
        (p2.x - p0.x).div(fromInt(6)).mul(fromUInt(tension));
      cPathPoints[0].y =
        p1.y +
        (p2.y - p0.y).div(fromInt(6)).mul(fromUInt(tension));

      cPathPoints[1].x =
        p2.x -
        (p3.x - p1.x).div(fromInt(6)).mul(fromUInt(tension));
      cPathPoints[1].y =
        p2.y -
        (p3.y - p1.y).div(fromInt(6)).mul(fromUInt(tension));

      pathParts[0] = "C";
      pathParts[1] = toDecimalString(cPathPoints[0].x);
      pathParts[2] = ",";
      pathParts[3] = toDecimalString(cPathPoints[0].y);
      pathParts[4] = ",";
      pathParts[5] = toDecimalString(cPathPoints[1].x);
      pathParts[6] = ",";
      pathParts[7] = toDecimalString(cPathPoints[1].y);
      pathParts[8] = ",";
      pathParts[9] = toDecimalString(p2.x);
      pathParts[10] = ",";
      pathParts[11] = toDecimalString(p2.y);
      cPathString = concatToString(cPathString, concatStringArray(pathParts));
    }

    return cPathString;
  }

  function closedSpline(Points[] memory pointsArr, uint256 tension)
    private
    pure
    returns (string memory)
  {
    Points[] memory loopedPoints = loopPoints(pointsArr);

    //start with M path
    string memory path = string(
      abi.encodePacked(
        "M",
        toDecimalString(loopedPoints[1].x),
        ",",
        toDecimalString(loopedPoints[1].y)
      )
    );

    //issueswith pointsArr arithmetic
    path = concatToString(
      path,
      generateCPath(loopedPoints, 1, loopedPoints.length - 2, tension)
    );
    return path;
  }

  function generateFilter(string memory spread)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<filter id="lightSource">',
          '<feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="10" result="turbulence"/>',
          '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',
          spread,
          '" result="turbResult" xChannelSelector="R" yChannelSelector="G"/>',
          "</filter>"
        )
      );
  }

  function generateStopColor(string memory color1, string memory color2)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<stop offset="0%" stop-opacity="1" stop-color="',
          color1,
          '" />',
          '<stop offset="100%" stop-opacity="1" stop-color="',
          color2,
          '" />'
        )
      );
  }

  function generateGradients(
    string memory speed,
    string memory color1,
    string memory color2,
    string memory color3,
    string memory color4
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<linearGradient id="grad0">'
          '<animateTransform attributeName="gradientTransform" attributeType="XML" type="rotate" from="0 0.5 0.5" to="-360 0.5 0.5" dur="',
          speed,
          's" repeatCount="indefinite"/>',
          generateStopColor(color1, color2),
          "</linearGradient>",
          '<linearGradient id="grad1">',
          '<animateTransform attributeName="gradientTransform" attributeType="XML" type="rotate" from="0 0.5 0.5" to="360 0.5 0.5" dur="',
          speed,
          's" repeatCount="indefinite"/>',
          generateStopColor(color3, color4),
          "</linearGradient>"
        )
      );
  }

  function generateBackground() private pure returns (string memory) {
    return '<rect width="400" height="400" fill="url(#grad0)"/>';
  }

  function generatePath(
    string memory path,
    string memory objectSpeed,
    string memory objectRotation
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "<g>",
          '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 200 200" to="360 200 200" dur="',
          objectRotation,
          's" repeatCount="indefinite"/>',
          '<path id="path" fill="url(#grad1)" filter="url(#lightSource)">',
          '<animate repeatCount="indefinite" attributeName="d" values="',
          path,
          '" dur="',
          objectSpeed,
          's"/>',
          "</path></g>"
        )
      );
  }

  function generateSVG(string memory dPath, Features memory features)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 400 400">',
          generateFilter(features.colorFeatures[0]),
          generateGradients(
            features.colorFeatures[1],
            features.colors[0],
            features.colors[1],
            features.colors[2],
            features.colors[3]
          ),
          generateBackground(),
          generatePath(
            dPath,
            features.colorFeatures[2],
            features.colorFeatures[3]
          ),
          "</svg>"
        )
      );
  }

  function generateColors(uint256 tokenId)
    private
    pure
    returns (string[] memory)
  {
    string[] memory colors = new string[](4);
    colors[0] = Color.generateColorHexCode("COLOR1", tokenId);
    colors[1] = Color.generateColorHexCode("COLOR2", tokenId);
    colors[2] = Color.generateColorHexCode("COLOR3", tokenId);
    colors[3] = Color.generateColorHexCode("COLOR4", tokenId);
    return colors;
  }

  function generateColorFeatures(uint256 tokenId)
    private
    pure
    returns (string[] memory)
  {
    string[] memory colorFeatures = new string[](4);

    uint256 speed2 = random(getSeed("SPEED2", tokenId), 1, 20);
    colorFeatures[0] = uintToStr(random(getSeed("SPREAD", tokenId), 0, 20));
    colorFeatures[1] = uintToStr(random(getSeed("SPEED1", tokenId), 5, 20));
    colorFeatures[2] = uintToStr(speed2);
    colorFeatures[3] = uintToStr(speed2 * 5);

    return colorFeatures;
  }

  function generateDPath(
    uint256 tokenId,
    uint256 numPoints,
    uint256 numFrames,
    uint256 radius
  ) private pure returns (string memory) {
    string memory firstFrame;
    string memory dPath;

    for (uint256 i = 0; i < numFrames; i++) {
      Points[] memory pointsArr = createPoints(
        uintToStr(i),
        tokenId,
        numPoints,
        radius
      );
      dPath = concatToString(dPath, closedSpline(pointsArr, 1));
      if (i == 0) firstFrame = dPath;
      dPath = concatToString(dPath, ";");
    }
    //add back first frame
    dPath = concatToString(dPath, firstFrame);
    return dPath;
  }

  function generateBlobFeatures(uint256 tokenId)
    private
    pure
    returns (uint256[] memory)
  {
    uint256[] memory blobFeatures = new uint256[](3);

    uint256 maxPoints = 11;
    uint256 minPoints = 3;
    uint256 numPoints = random(
      getSeed("NUMPOINTS", tokenId),
      minPoints,
      maxPoints
    );
    uint256 numFrames = 5;
    uint256 radius = random(getSeed("RADIUS", tokenId), 25, 100);

    blobFeatures[0] = numPoints;
    blobFeatures[1] = numFrames;
    blobFeatures[2] = radius;
    return blobFeatures;
  }

  struct Features {
    string[] colors;
    string[] colorFeatures;
    uint256[] blobFeatures;
  }

  struct JSONMeta {
    string texture;
    string energy;
    string blob_color_1;
    string blob_color_2;
    string back_color_1;
    string back_color_2;
    string close;
  }

  function generateColorFeatures(Features memory features)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"Blob color #1","value":"',
          features.colors[2],
          '"},',
          '{"trait_type":"Blob color #2","value":"',
          features.colors[3],
          '"},',
          '{"trait_type":"Background color #1","value":"',
          features.colors[0],
          '"},',
          '{"trait_type":"Background color #2","value":"',
          features.colors[1]
        )
      );
  }

  function generateColorAttributes(Features memory features)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"Texture","value":',
          features.colorFeatures[0],
          "},",
          '{"trait_type":"Energy","value":',
          features.colorFeatures[2],
          "},",
          generateColorFeatures(features),
          '"}'
        )
      );
  }

  function generateAttributes(Features memory features)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '"attributes": [',
          '{"trait_type":"Entropy","value":',
          uintToStr(features.blobFeatures[0]),
          "},",
          '{"trait_type":"Girth","value":',
          uintToStr(features.blobFeatures[2]),
          "},",
          generateColorAttributes(features),
          "]"
        )
      );
  }

  function generateJSONMeta(
    Features memory features,
    string memory svgData,
    uint256 tokenId
  ) internal pure returns (string memory) {
    string memory jsonMeta = string(
      abi.encodePacked(
        '{"name": "BLOB #',
        uintToStr(tokenId),
        '",',
        '"description": "8108 (BLOB) is the first on-chain generative animated NFT",',
        generateAttributes(features),
        ",",
        '"image": "',
        svgData,
        '"',
        "}"
      )
    );

    return jsonMeta;
  }

  function generateTokenURI(uint256 tokenId)
    internal
    pure
    returns (string memory)
  {
    Features memory features;
    features.colors = generateColors(tokenId);
    features.colorFeatures = generateColorFeatures(tokenId);
    features.blobFeatures = generateBlobFeatures(tokenId);

    //59.18 int
    string memory dPath = generateDPath(
      tokenId,
      features.blobFeatures[0],
      features.blobFeatures[1],
      features.blobFeatures[2]
    );

    string memory svgData = concatToString(
      "data:image/svg+xml;base64,",
      Base64.encode(bytes(generateSVG(dPath, features)))
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(bytes(generateJSONMeta(features, svgData, tokenId)))
        )
      );
  }
}
