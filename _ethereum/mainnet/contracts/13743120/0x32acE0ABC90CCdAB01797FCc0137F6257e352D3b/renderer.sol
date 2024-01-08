// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./gear_types.sol";
import "./base64.sol";

pragma solidity 0.8.7;
pragma abicoder v2;

contract ChainRunnerGearRenderer is Ownable {
  using Strings for uint256;
  using Strings for uint8;

  struct TraitImageInput {
    uint8 armamentId;
    uint8 classId;
    uint8 rarityId;
    string image;
  }

  uint256 internal constant MAX = 5000;
  string[7] internal _traits = [
    "Background",
    "Armament",
    "Class",
    "Means of Acquisition",
    "Faction",
    "Rarity",
    "Power Level"
  ];

  mapping(uint8 => mapping(uint8 => mapping(uint8 => string))) public traitImages;
  mapping(uint8 => mapping(uint8 => string)) public traitNames;
  mapping(uint8 => string) public factionImages;

  function uploadTraitNames(
    uint8 traitType,
    uint8[] calldata traitIds,
    string[] calldata traits
  ) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint i = 0; i < traits.length; i++) {
      traitNames[traitType][traitIds[i]] = traits[i];
    }
  }

  function uploadTraitImages(TraitImageInput[] calldata inputs) external onlyOwner {
    for (uint8 i = 0; i < inputs.length; i++) {
      TraitImageInput memory inp = inputs[i];
      traitImages[inp.armamentId][inp.classId][inp.rarityId] = inp.image;
    }
  }

  function uploadFactionImages(string[] calldata inputs) external onlyOwner {
    for (uint8 i = 0; i < inputs.length; i++) {
      factionImages[i] = inputs[i];
    }
  }

  function tokenURI(uint256 tokenId, GearTypes.Gear memory g) external view returns (string memory) {
    string memory image = Base64.encode(bytes(generateSVGImage(g)));

    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              traitNames[5][g.rarity],
              ' ',
              traitNames[3][g.meansOfAcquisition],
              ' ',
              traitNames[4][g.faction],
              ' ',
              traitNames[1][g.armament],
              ' ',
              traitNames[2][g.class],
              ' #',
              tokenId.toString(),
              '", ',
              '"attributes": ',
              compileAttributes(g),
              ', "image": "',
              "data:image/svg+xml;base64,",
              image,
              '"}'
            )
          )
        )
      )
    );
  }

  function generateSVGImage(GearTypes.Gear memory params) internal view returns (string memory) {
    return string(
      abi.encodePacked(
        generateSVGHeader(),
        generateBackground(params.background),
        generateArmament(params),
        generateFaction(params),
        "</svg>"
      )
    );
  }

  function generateSVGHeader() private pure returns (string memory) {
    return
    string(
      abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
        ' viewBox="0 0 480 480" style="enable-background:new 0 0 480 480;" xml:space="preserve">'
      )
    );
  }

  function generateArmament(GearTypes.Gear memory gear) internal view returns (string memory) {
    bytes memory svgString = abi.encodePacked(
      '<image x="0" y="0" width="480" height="480" image-rendering="pixelated" preserveAspectRatio="xMidYMid" href="data:image/png;base64,',
      traitImages[gear.armament][gear.class][gear.rarity],
      '"/>'
    );
    return string(svgString);
  }

  function generateFaction(GearTypes.Gear memory gear) internal view returns (string memory) {
    bytes memory svgString = abi.encodePacked(
      '<image x="0" y="0" width="480" height="480" image-rendering="pixelated" preserveAspectRatio="xMidYMid" href="data:image/png;base64,',
      factionImages[gear.faction],
      '"/>'
    );
    return string(svgString);
  }

  function generateBackground(uint8 backgroundId) internal view returns (string memory) {
    return string(
      abi.encodePacked(
        '<rect x="0" y="0" style="width:480px;height: 480px;" fill="#',
        traitNames[0][backgroundId],
        '"></rect>'
      )
    );
  }

  function compileAttributes(GearTypes.Gear memory g) public view returns (string memory) {
    string memory traits;
    traits = string(abi.encodePacked(
      attributeForTypeAndValue(_traits[0], traitNames[0][g.background]),',',
      attributeForTypeAndValue(_traits[1], traitNames[1][g.armament]),',',
      attributeForTypeAndValue(_traits[2], traitNames[2][g.class]),',',
      attributeForTypeAndValue(_traits[3], traitNames[3][g.meansOfAcquisition]),',',
      attributeForTypeAndValue(_traits[4], traitNames[4][g.faction]),',',
      attributeForTypeAndValue(_traits[5], traitNames[5][g.rarity]),',',
      attributeForNumberAndValue(_traits[6], g.powerLevel)
    ));
    return string(abi.encodePacked(
      '[',
      traits,
      ']'
    ));
  }

  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  function attributeForNumberAndValue(string memory traitType, uint8 value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"display_type":"number","trait_type":"',
      traitType,
      '","value": ',
      value.toString(),
      '}'
    ));
  }
}