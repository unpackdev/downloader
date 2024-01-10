// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "./Base64.sol";

import "./Tiny721.sol";

/**
  @title On-chain generative bees.

  This contract generates a piece of pseudorandom data upon each token's mint.
  This data is then used to generate 100% on-chain an SVG of a bee with
  associated metadata.

  March 9th, 2022.
*/
contract Beelinez is
  Tiny721
{
  using Strings for uint256;

  /// The timestamp when the bees launched. This is used to give bees an age.
  uint256 public immutable startTime;

  /// A mapping from each token ID to the pseudorandom hash when it was minted.
  mapping ( uint256 => uint256 ) public mintData;

  /// A mapping from each token ID to the time when it was minted.
  mapping ( uint256 => uint256 ) public mintTime;

  /**
    This struct is used to define a color which is used elsewhere to generate
    the actual on-chain SVG.

    @param value The value of the color expressed as an SVG-compatible color
      string. This can be a specific color string, such as `rgb(255,255,255)` or
      a recognized color code such as `salmon`.
    @param friendlyName The friendly name of the color which will be used when
      building the on-chain metadata attributes.
  */
  struct Color {
    string value;
    string friendlyName;
  }

  /// A storage array of all possible background colors.
  Color[] private BACKGROUND_COLORS;

  /// A storage array of all possible primary bee colors.
  Color[] private PRIMARY_COLORS;

  /// A storage array of all possible secondary bee colors.
  Color[] private SECONDARY_COLORS;

  /// A storage array of all possible bee wing colors.
  Color[] private WING_COLORS;

  /// A storage array of all possible bee primary eye colors.
  Color[] private PRIMARY_EYE_COLORS;

  /// A storage array of all possible bee secondary eye colors.
  Color[] private SECONDARY_EYE_COLORS;

  /**
    This struct is used to define a piece of generic switching logic based on
    integer sentinel values. In this case, it is used to define the patterns
    being colored in with our `Color`s.

    @param value The sentinel value of the pattern.
    @param friendlyName The friendly name which will be used when building the
      on-chain metadata attributes.
  */
  struct Pattern {
    uint256 value;
    string friendlyName;
  }

  /// A storage array of all possible tail patterns.
  Pattern[] private TAIL_PATTERNS;

  /// A storage array of all possible eye patterns.
  Pattern[] private EYE_PATTERNS;

  /**
    This struct represents a single generated bee.

    @param backgroundColor The background color of the bee, tracked as an index
      of the background color storage array.
    @param primaryColor The primary color of the bee, tracked as an index of the
      global primary color storage array.
    @param secondaryColor The secondary color of the bee, tracked as an index of
      the global secondary color storage array.
    @param tailPattern The pattern used to generate the bee's tail, tracked as
      an index of the global tail pattern storage array.
    @param tailSegments The number of segments in the bee's tail.
    @param bodyLength The length of the bee's body.
    @param wingColor The color of the bee's wings, tracked as an index of the
      global wing color storage array.
    @param wingLength The length of the bee's wings.
    @param primaryEyeColor The primary color of the bee's eye, tracked as an
      index of the global primary eye color storage array.
    @param secondaryEyeColor The secondary color of the bee's eye, tracked as an
      index of the global secondary eye color storage array.
    @param eyePattern The pattern used to generate the bee's eyes, tracked as an
      index of the global eye pattern storage array.
    @param eyeSegments The number of eyes the bee has.
    @param age The age of the bee in days since the contract was launched.
    @param image The final composited image of the bee.
  */
  struct Bee {
    uint256 backgroundColor;
    uint256 primaryColor;
    uint256 secondaryColor;
    uint256 tailPattern;
    uint256 tailSegments;
    uint256 bodyLength;
    uint256 wingColor;
    uint256 wingLength;
    uint256 primaryEyeColor;
    uint256 secondaryEyeColor;
    uint256 eyePattern;
    uint256 eyeSegments;
    uint256 age;
    string image;

    // Scratchpad variables.
    uint256 tailStart;
    uint256 bodyStart;
    uint256 eyesStart;
    string wingComponent;
  }

  /**
    Construct a new instance of this ERC-721 contract.

    @param _name The name to assign to this item collection contract.
    @param _symbol The ticker symbol of this item collection.
    @param _cap The maximum number of tokens that may be minted.
  */
  constructor (
    string memory _name,
    string memory _symbol,
    uint256 _cap
  ) Tiny721(_name, _symbol, "", _cap) {
    startTime = block.timestamp;

    // Populate the background color array.
    BACKGROUND_COLORS.push(Color({
      value: "rgb(82,183,136)",
      friendlyName: "Mint"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(64,145,108)",
      friendlyName: "Kermit"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(45,106,79)",
      friendlyName: "Toad"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(27,67,50)",
      friendlyName: "Forest"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(8,28,21)",
      friendlyName: "Dark Forest"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(125,125,125)",
      friendlyName: "Gray"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(181,121,155)",
      friendlyName: "Rose"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(93,133,133)",
      friendlyName: "Teal"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(164,45,24)",
      friendlyName: "Blood"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(204,127,133)",
      friendlyName: "Lips"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(168,75,73)",
      friendlyName: "Flesh"
    }));
    BACKGROUND_COLORS.push(Color({
      value: "rgb(124,141,130)",
      friendlyName: "Mold"
    }));

    // Populate the primary color array.
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,123,0)",
      friendlyName: "Pumpkin"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,136,0)",
      friendlyName: "SunnyD"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,149,0)",
      friendlyName: "Tang"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,162,0)",
      friendlyName: "Orange Crush"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,170,0)",
      friendlyName: "Fanta"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,183,0)",
      friendlyName: "Peach"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,195,0)",
      friendlyName: "Honey"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,208,0)",
      friendlyName: "School Bus"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,221,0)",
      friendlyName: "Lemon"
    }));
    PRIMARY_COLORS.push(Color({
      value: "rgb(255,234,0)",
      friendlyName: "Lightning"
    }));

    // Populate the secondary color array.
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,0,0)",
      friendlyName: "Void"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(47,31,31)",
      friendlyName: "Brown"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(47,31,31)",
      friendlyName: "Brown"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(47,31,31)",
      friendlyName: "Brown"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(47,31,31)",
      friendlyName: "Brown"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(47,31,31)",
      friendlyName: "Brown"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(3,4,94)",
      friendlyName: "Navy"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(2,62,138)",
      friendlyName: "Royal"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,119,182)",
      friendlyName: "Glass"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,150,199)",
      friendlyName: "Slurpee"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(0,180,216)",
      friendlyName: "Electric"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(72,202,228)",
      friendlyName: "Glacier"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(144,224,239)",
      friendlyName: "Ice"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(173,232,244)",
      friendlyName: "Cold"
    }));
    SECONDARY_COLORS.push(Color({
      value: "rgb(202,240,248)",
      friendlyName: "Frigid"
    }));

    /// Populate the wing color array.
    WING_COLORS.push(Color({
      value: "rgb(237,242,251)",
      friendlyName: "Powder"
    }));
    WING_COLORS.push(Color({
      value: "rgb(226,234,252)",
      friendlyName: "Ghost"
    }));
    WING_COLORS.push(Color({
      value: "rgb(215,227,252)",
      friendlyName: "Clear"
    }));
    WING_COLORS.push(Color({
      value: "rgb(204,219,253)",
      friendlyName: "Crystal"
    }));
    WING_COLORS.push(Color({
      value: "rgb(193,211,254)",
      friendlyName: "Air"
    }));
    WING_COLORS.push(Color({
      value: "rgb(182,204,254)",
      friendlyName: "Wind"
    }));
    WING_COLORS.push(Color({
      value: "rgb(171,196,255)",
      friendlyName: "Stream"
    }));

    /// Populate the primary eye color array.
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(248,249,250)",
      friendlyName: "Bone"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(233,236,239)",
      friendlyName: "Offwhite"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(222,226,230)",
      friendlyName: "Dandruff"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(206,212,218)",
      friendlyName: "Ash"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(173,181,189)",
      friendlyName: "Death Star"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(108,117,125)",
      friendlyName: "2B Pencil"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(73,80,87)",
      friendlyName: "Goth Tears"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(52,58,64)",
      friendlyName: "Shade"
    }));
    PRIMARY_EYE_COLORS.push(Color({
      value: "rgb(33,37,41)",
      friendlyName: "Coal"
    }));

    /// Populate the secondary eye color array.
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(255,173,173)",
      friendlyName: "Red Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(255,214,165)",
      friendlyName: "Orange Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(253,255,182)",
      friendlyName: "Yellow Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(202,255,191)",
      friendlyName: "Green Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(155,246,255)",
      friendlyName: "Blue Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(160,196,255)",
      friendlyName: "Violet Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(189,178,255)",
      friendlyName: "Purple Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(255,198,255)",
      friendlyName: "Rose Chalk"
    }));
    SECONDARY_EYE_COLORS.push(Color({
      value: "rgb(255,255,252)",
      friendlyName: "White Chalk"
    }));

    // Populate the tail pattern array.
    TAIL_PATTERNS.push(Pattern({
      value: 0,
      friendlyName: "Right"
    }));
    TAIL_PATTERNS.push(Pattern({
      value: 1,
      friendlyName: "Left"
    }));
    TAIL_PATTERNS.push(Pattern({
      value: 2,
      friendlyName: "Band"
    }));

    /// Populate the eye pattern array.
    EYE_PATTERNS.push(Pattern({
      value: 0,
      friendlyName: "Right"
    }));
    EYE_PATTERNS.push(Pattern({
      value: 0,
      friendlyName: "Left"
    }));
  }

  /**
    Retrieve the token's pregenerated pseudorandom value and mix it with a given
    `_index` to keep it pseudorandom on successive calls.

    @param _id The ID of the token to retrieve the pregenerated value for.
    @param _index An index to prevent duplicating the random roll.

    @return A pseudorandom value.
  */
  function _getRandom (
    uint256 _id,
    uint256 _index
  ) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      mintData[_id],
      _index
    )));
  }

  /**
    Generate an SVG string representing the background of a bee image.

    @param _id The ID of the token to generate the background for.
    @param _bee The bee to modify the background index of.

    @return The item's background component.
  */
  function _generateBackground (
    uint256 _id,
    Bee memory _bee
  ) private view returns (string memory) {

    // Select a random background color.
    uint256 backgroundIndex = _getRandom(_id, 1000) % BACKGROUND_COLORS.length;
    _bee.backgroundColor = backgroundIndex;
    Color memory backgroundColor = BACKGROUND_COLORS[backgroundIndex];

    // Return the generated SVG element.
    string memory background = string(abi.encodePacked(
      "<rect width=\"100%\" height=\"100%\" fill=\"",
      backgroundColor.value,
      "\" />"
    ));
    return background;
  }

  /**
    Generate an SVG string representing the tail of a bee image.

    @param _id The ID of the token to generate the tail for.
    @param _bee The bee to modify the background index of.
    @param _tailPatternScheme The index of the pattern being used to determine
      the tail pattern.
    @param _tailSegments The number of segments in the tail being drawn.
    @param _primaryColor The primary color value for filling in the tail.

    @return The item's tail component.
  */
  function _generateTail (
    uint256 _id,
    Bee memory _bee,
    uint256 _tailPatternScheme,
    uint256 _tailSegments,
    uint256 _primaryColor
  ) private view returns (string memory) {

    // Select a random secondary bee color.
    uint256 colorIndex = _getRandom(_id, 2000) % SECONDARY_COLORS.length;
    _bee.secondaryColor = colorIndex;
    Color memory secondaryColor = SECONDARY_COLORS[colorIndex];

    // Generate the tail (if there is one).
    string memory tail;
    for (uint256 i = 0; i < _tailSegments; i++) {

      // Generate the right-handed pattern.
      if (_tailPatternScheme == 0) {
        tail = string(abi.encodePacked(
          tail,
          "<rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          secondaryColor.value,
          "\" /><rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * 1 + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          PRIMARY_COLORS[_primaryColor].value,
          "\" />"
        ));

      // Generate the left-handed pattern.
      } else if (_tailPatternScheme == 1) {
        tail = string(abi.encodePacked(
          tail,
          "<rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          PRIMARY_COLORS[_primaryColor].value,
          "\" /><rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * 1 + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          secondaryColor.value,
          "\" />"
        ));

      // Generate the banded pattern.
      } else if (_tailPatternScheme == 2) {
        tail = string(abi.encodePacked(
          tail,
          "<rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * (i * 3)).toString(),
          "%\" y=\"50%\" fill=\"",
          PRIMARY_COLORS[_primaryColor].value,
          "\" /><rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * 1 + 3 * (i * 3)).toString(),
          "%\" y=\"50%\" fill=\"",
          secondaryColor.value,
          "\" /><rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.tailStart + 3 * 2 + 3 * (i * 3)).toString(),
          "%\" y=\"50%\" fill=\"",
          PRIMARY_COLORS[_primaryColor].value,
          "\" />"
        ));
      }
    }
    return tail;
  }

  /**
    Generate an SVG string representing the body of a bee image.

    @param _bee The bee to generate the body for.
    @param _bodyLength The length of the bee body to draw.
    @param _primaryColor The primary color to fill in the bee with.

    @return The item's body component.
  */
  function _generateBody (
    Bee memory _bee,
    uint256 _bodyLength,
    string memory _primaryColor
  ) private pure returns (string memory) {

    // Generate the body.
    string memory body;
    for (uint256 i = 0; i < _bodyLength; i++) {
      body = string(abi.encodePacked(
        body,
        "<rect width=\"3%\" height=\"3%\" x=\"",
        (_bee.bodyStart + 3 * i).toString(),
        "%\" y=\"50%\" fill=\"",
        _primaryColor,
        "\" />"
      ));
    }
    return body;
  }

  /**
    Generate an SVG string representing the wings of a bee image.

    @param _id The ID of the token to generate the wings for.
    @param _bee The bee to modify the background index of.
    @param _startingX The starting x-position to begin drawing the wings at;
      this is provided in order to center the bee in the generated image.
    @param _bodyLength The length of the body to place wings atop.

    @return The item's wing component.
  */
  function _generateWings (
    uint256 _id,
    Bee memory _bee,
    uint256 _startingX,
    uint256 _bodyLength
  ) private view returns (string memory) {

    // Select a random wing color.
    uint256 colorIndex = _getRandom(_id, 3000) % WING_COLORS.length;
    _bee.wingColor = colorIndex;
    Color memory wingColor = WING_COLORS[colorIndex];

    // Select a random wing height.
    uint256[3] memory WING_HEIGHTS = [
      uint256(1),
      uint256(1),
      uint256(2)
    ];
    uint256 wingHeight = WING_HEIGHTS[
      _getRandom(_id, 3001) % WING_HEIGHTS.length
    ];
    _bee.wingLength = wingHeight;

    // Generate two random wings on the body.
    uint256 firstWingLength = (_getRandom(_id, 3002) % (_bodyLength - 2));
    uint256 firstWing = _startingX + 3 * firstWingLength;
    uint256 secondWing = firstWing + 3 * 2
      + 3 * (_getRandom(_id, 3003) % (_bodyLength - (firstWingLength + 2)));
    string memory wings;
    for (uint256 i = 0; i < wingHeight; i++) {
      wings = string(abi.encodePacked(
        wings,
        "<rect width=\"3%\" height=\"3%\" x=\"",
        (firstWing).toString(),
        "%\" y=\"",
        (47 - 3 * i).toString(),
        "%\" fill=\"",
        wingColor.value,
        "\" /><rect width=\"3%\" height=\"3%\" x=\"",
        (secondWing).toString(),
        "%\" y=\"",
        (47 - 3 * i).toString(),
        "%\" fill=\"",
        wingColor.value,
        "\" />"
      ));
    }
    return wings;
  }

  /**
    Generate an SVG string representing the eyes of a bee image.

    @param _id The ID of the token to generate the eyes for.
    @param _bee The bee to modify the background index of.
    @param _eyePatternScheme The index of the pattern being used to determine
      the eye drawing.
    @param _eyeSegments The number of eye pattern segments to draw.

    @return The item's eyes component.
  */
  function _generateEyes (
    uint256 _id,
    Bee memory _bee,
    uint256 _eyePatternScheme,
    uint256 _eyeSegments
  ) private view returns (string memory) {

    // Select a random primary eye color.
    uint256 primaryIndex = _getRandom(_id, 4000) % PRIMARY_EYE_COLORS.length;
    _bee.primaryEyeColor = primaryIndex;
    Color memory primaryColor = PRIMARY_EYE_COLORS[primaryIndex];

    // Select a random secondary eye color.
    uint256 secondIndex = _getRandom(_id, 4001) % SECONDARY_EYE_COLORS.length;
    _bee.secondaryEyeColor = secondIndex;
    Color memory secondaryColor = SECONDARY_EYE_COLORS[secondIndex];

    // Generate the eyes.
    string memory eyes;
    for (uint256 i = 0; i < _eyeSegments; i++) {

      // Generate the right-handed pattern.
      if (_eyePatternScheme == 0) {
        eyes = string(abi.encodePacked(
          eyes,
          "<rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.eyesStart + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          secondaryColor.value,
          "\" /><rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.eyesStart + 3 + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          primaryColor.value,
          "\" />"
        ));

      // Generate the left-handed pattern.
      } else if (_eyePatternScheme == 1) {
        eyes = string(abi.encodePacked(
          eyes,
          "<rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.eyesStart + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          primaryColor.value,
          "\" /><rect width=\"3%\" height=\"3%\" x=\"",
          (_bee.eyesStart + 3 + 3 * (i * 2)).toString(),
          "%\" y=\"50%\" fill=\"",
          secondaryColor.value,
          "\" />"
        ));
      }
    }
    return eyes;
  }

  /**
    A helper function to generate the age of a particular bee. This is required
    in order to avoid a stack-too-deep error.

    @param _id The ID of the bee to get the age of.

    @return The age of the bee in terms of "which day since launch" was it
      minted on.
  */
  function _getAge (
    uint256 _id
  ) private view returns (uint256) {
    return 1 + ((mintTime[_id] - startTime) / (24 * 60 * 60));
  }

  /**
    Generate an SVG string representing the bee image and collect its metadata.

    @param _id The ID of the token to generate the bee for.
    @param _primaryColorIndex The index of the primary color.
    @param _tailPatternScheme The index of the pattern being used to determine
      the tail pattern.
    @param _tailSegments The number of segments in the tail being drawn.
    @param _eyePatternScheme The index of the pattern being used to determine
      the eye drawing.
    @param _eyeSegments The number of eye pattern segments to draw.

    @return The item's bee image.
  */
  function _generateBee (
    uint256 _id,
    uint256 _primaryColorIndex,
    uint256 _tailPatternScheme,
    uint256 _tailSegments,
    uint256 _eyePatternScheme,
    uint256 _eyeSegments
  ) private view returns (Bee memory) {

    // Perform pattern-matching to determine the length of the bee.
    uint256 tailLength = 0;
    if (_tailPatternScheme == 0 || _tailPatternScheme == 1) {
      tailLength += 2 * _tailSegments;
    } else {
      tailLength += 3 * _tailSegments;
    }
    uint256 bodyLength = 4 + (_getRandom(_id, 5) % 4);
    uint256 eyeLength = 0;
    if (_eyePatternScheme == 0 || _eyePatternScheme == 1) {
      eyeLength += 2 * _eyeSegments;
    }

    /*
      Prepare an output bee. Due to stack depth limitations, most of the fields
      in this bee must be set by passing it into the various `_generate` methods
      which will modify its internal state.
    */
    Bee memory outputBee = Bee({
      backgroundColor: 0, // This field is set by `_generateBackground`.
      primaryColor: _primaryColorIndex,
      secondaryColor: 0, // This field is set by `_generateTail`.
      tailPattern: _tailPatternScheme,
      tailSegments: _tailSegments,
      bodyLength: bodyLength,
      wingColor: 0, // This field is set by `_generateWings`.
      wingLength: 0, // This field is set by `_generateWings`.
      primaryEyeColor: 0, // This field is set by `_generateEyes`.
      secondaryEyeColor: 0, // This field is set by `_generateEyes`.
      eyePattern: _eyePatternScheme,
      eyeSegments: _eyeSegments,
      age: _getAge(_id),
      image: "",

      // The scratch-pad portions of the bee struct for data operations.
      tailStart: 47 - 3 * ((tailLength + bodyLength + eyeLength) / 2),
      bodyStart: 47 - 3 * ((tailLength + bodyLength + eyeLength) / 2)
        + 3 * tailLength,
      eyesStart: 47 - 3 * ((tailLength + bodyLength + eyeLength) / 2)
        + 3 * tailLength + 3 * bodyLength,
      wingComponent: ""
    });

    outputBee.wingComponent = _generateWings(
      _id,
      outputBee,
      outputBee.bodyStart,
      bodyLength
    );

    // Glue all of this madness together to create the bee SVG.
    outputBee.image = string(abi.encodePacked(
      "<svg version=\"1.1\" width=\"1000\" height=\"1000\" ",
      "viewBox=\"0 0 1000 1000\" stroke-linecap=\"round\" ",
      "xmlns=\"http://www.w3.org/2000/svg\" ",
      "xmlns:xlink=\"http://www.w3.org/1999/xlink\">",
      _generateBackground(
        _id,
        outputBee
      ),
      _generateTail(
        _id,
        outputBee,
        _tailPatternScheme,
        _tailSegments,
        _primaryColorIndex
      ),
      _generateBody(
        outputBee,
        bodyLength,
        PRIMARY_COLORS[_primaryColorIndex].value
      ),
      outputBee.wingComponent,
      _generateEyes(
        _id,
        outputBee,
        _eyePatternScheme,
        _eyeSegments
      ),
      "</svg>"
    ));

    // Return a Bee with its image and data.
    return outputBee;
  }

  /**
    A private helper function to return a formatted attribute string for display
    on NFT marketplaces.

    @param _traitName The name of the trait to construct an object for.
    @param _value The value of the trait.
    @param _isNumeric Whether or not the trait is numeric.

    @return The formatted attribute object string.
  */
  function _attribute (
    string memory _traitName,
    string memory _value,
    bool _isNumeric
  ) private pure returns (string memory) {

    // If the attribute is not numeric, we must wrap it in quotes.
    string memory wrappedValue = _value;
    if (!_isNumeric) {
      wrappedValue = string(abi.encodePacked(
        "\"",
        _value,
        "\""
      ));
    }

    // Return the formatted attribute.
    return string(abi.encodePacked(
      "{ \"trait_type\": \"",
      _traitName,
      "\", \"value\": ",
      wrappedValue,
      " }"
    ));
  }

  /**
    To avoid a stack-too-deep error, we must generate part of the attributes
    array for a given bee using this function.

    @param _bee The bee to generate partial attributes for.

    @return Part of the attributes array for a bee.
  */
  function _generatePartialAttributes (
    Bee memory _bee
  ) private view returns (string memory) {
    return string(abi.encodePacked(
      "[",
      _attribute(
        "Background",
        BACKGROUND_COLORS[_bee.backgroundColor].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Body Color",
        PRIMARY_COLORS[_bee.primaryColor].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Tail Color",
        SECONDARY_COLORS[_bee.secondaryColor].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Tail Pattern",
        TAIL_PATTERNS[_bee.tailPattern].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Tail Segments",
        (_bee.tailSegments).toString(),
        true
      ),
      ","
    ));
  }

  /**
    Generate an array of metadata attributes for a given bee.

    @param _bee The bee to generate attributes for.

    @return The array of attributes as a string.
  */
  function _generateAttributes (
    Bee memory _bee
  ) private view returns (string memory) {
    return string(abi.encodePacked(
      _generatePartialAttributes(_bee),
      _attribute(
        "Body Length",
        (_bee.bodyLength).toString(),
        true
      ),
      ",",
      _attribute(
        "Wing Color",
        WING_COLORS[_bee.wingColor].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Wing Length",
        (_bee.wingLength).toString(),
        true
      ),
      ",",
      _attribute(
        "Eye Color",
        PRIMARY_EYE_COLORS[_bee.primaryEyeColor].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Iris Color",
        SECONDARY_EYE_COLORS[_bee.secondaryEyeColor].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Eye Pattern",
        EYE_PATTERNS[_bee.eyePattern].friendlyName,
        false
      ),
      ",",
      _attribute(
        "Eye Segments",
        (_bee.eyeSegments).toString(),
        true
      ),
      ",",
      _attribute(
        "Age",
        (_bee.age).toString(),
        true
      ),
      "]"
    ));
  }

  /**
    Directly return the metadata of the token with the specified `_id` as a
    packed base64-encoded URI.

    @param _id The ID of the token to retrive a metadata URI for.

    @return The metadata of the token with the ID of `_id` as a base64 URI.
  */
  function tokenURI (
    uint256 _id
  ) external view virtual override returns (string memory) {
    if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }

    // Select a random primary bee color.
    uint256 colorIndex = _getRandom(_id, 0) % PRIMARY_COLORS.length;

    // Select a random tiling pattern and length for the tail.
    uint256 tailPatternScheme = _getRandom(_id, 1) % TAIL_PATTERNS.length;
    uint256 tailSegments = 1 + (_getRandom(_id, 2) % 4);

    // Select a random tiling pattern and length for the eyes.
    uint256 eyePatternScheme = _getRandom(_id, 3) % EYE_PATTERNS.length;
    uint256 eyeSegments = 2;

    // Generate the full SVG string of the token's image.
    Bee memory bee = _generateBee(
      _id,
      colorIndex,
      tailPatternScheme,
      tailSegments,
      eyePatternScheme,
      eyeSegments
    );

    // Encode the SVG into a base64 data URI.
    string memory encodedImage = string(abi.encodePacked(
      "data:image/svg+xml;base64,",
      Base64.encode(
        bytes(string(abi.encodePacked(bee.image)))
      )
    ));

    // Create the attributes array from friendly details.
    string memory attributes = _generateAttributes(bee);

    // Return the base64-encoded packed metadata.
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              "{ \"name\": \"",
              "Beelinez ",
              (_id).toString(),
              "\", \"description\": \"bzz bzz\", ",
              "\"attributes\": ",
              attributes,
              ", \"image\": \"",
              encodedImage,
              "\"}"
            )
          )
        )
      )
    );
  }

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint_Qgo (
    address _recipient,
    uint256 _amount
  ) public override onlyAdmin {

    // Store a piece of pseudorandom data tied to each item that will be minted.
    uint256 startTokenId = nextId;
    unchecked {
      uint256 updatedIndex = startTokenId;
      for (uint256 i; i < _amount; i++) {
        mintData[updatedIndex] = uint256(keccak256(abi.encodePacked(
          _msgSender(),
          _recipient,
          _amount,
          updatedIndex,
          block.timestamp,
          block.difficulty
        )));
        mintTime[updatedIndex] = block.timestamp;
        updatedIndex++;
      }
    }

    // Actually mint the items.
    super.mint_Qgo(_recipient, _amount);
  }
}
