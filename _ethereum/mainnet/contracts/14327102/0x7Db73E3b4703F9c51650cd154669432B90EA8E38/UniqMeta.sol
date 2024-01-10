// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Base64.sol";

abstract contract UniqMeta is ERC721 {

  string[] private actTypesCasual = [
    "Dai",
    "Nedaj",
    "Verni",
    "Neverni",
    "Bei",
    "Nebei",
    "Vyrvi",
    "Zadery",
    "Drygai",
    "Gulyai",
    "Kruty",
    "Hapai",
    "Tyagni",
    "Zatuly",
    "Paly",
    "Ubij",
    "Kruty",
    "Netudy"
  ];

  string[] private actTypesAbstract = [
    "Telip",
    "Zabi",
    "Poshiv",
    "Sip",
    "Hrum",
    "Dogad",
    "Koval",
    "Dorosh"
  ];

  string[] private actTypesFood = [
    "Kusai",
    "Nekusai",
    "Pyi",
    "Nepyi",
    "Yizh",
    "Neyizh",
    "Zhri",
    "Pechi",
    "Zhui"
  ];

  string[] private objTypesAbstract = [
    "enko",
    "ajlo",
    "ovich",
    "yuha",
    "alo"
  ];

  string[] private objTypesCasual = [
    "Dim",
    "Gora",
    "Rika",
    "Shlyah",
    "Derevo",
    "Hvist",
    "Zyb",
    "Oko",
    "Noga",
    "Bok",
    "Bat\'ko",
    "Shapka",
    "Groshi",
    "Drabyna",
    "Hatka"
  ];

  string[] private objTypesFood = [
    "Borsh",
    "Chasnyk",
    "Hlib",
    "Gorilka",
    "Salo",
    "Kulish",
    "Kovbasa",
    "Shkvarki",
    "Syr",
    "Oseledets",
    "Kasha",
    "Kulaga",
    "Uzvar",
    "Smuzi"
  ];

  function getBackground(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Background", 20);
  }

  function getHead(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Head", 24);
  }

  function getMustache(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Mustache", 199);
  }

  function getForelock(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Forelock", 114);
  }

  function getSmockingPipe(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "SmockingPipe", 20);
  }

  function getEarring(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Earring", 26);
  }

  function getPistol(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Pistol", 144);
  }

  function getSaber(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Saber", 54);
  }

  function getBeard(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Mace", 216);
  }

  function getMace(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Beard", 144);
  }

  function getEyes(uint256 tokenId) public pure returns (uint256) {
    return randomIndex(tokenId, "Eyes", 40);
  }

  function getNickName(uint256 tokenId) public view returns (string memory) {
    uint256 actType = randomIndex(tokenId, "action", 299);
    string memory prefix;
    string memory postfix;

    if (actType >= 0 && actType < 99) {
      prefix = random(tokenId, "casual", actTypesCasual);
      postfix = random(tokenId, "casual", objTypesCasual);
    } else if (actType >= 100 && actType < 198) {
      prefix = random(tokenId, "food", actTypesFood);
      postfix = random(tokenId, "food", objTypesFood);
    } else {
      prefix = random(tokenId, "abstract", actTypesAbstract);
      postfix = random(tokenId, "abstract", objTypesAbstract);
    }

    return string(abi.encodePacked(prefix, postfix));
  }

  function getTraits(uint256 tokenId) external pure returns (uint256[] memory traits) {
    traits = new uint256[](11);
    traits[0] = getBackground(tokenId);
    traits[1] = getHead(tokenId);
    traits[2] = getMustache(tokenId);
    traits[3] = getForelock(tokenId);
    traits[4] = getBeard(tokenId);
    traits[5] = getSmockingPipe(tokenId);
    traits[6] = getEarring(tokenId);
    traits[7] = getPistol(tokenId);
    traits[8] = getSaber(tokenId);
    traits[9] = getMace(tokenId);
    traits[10] = getEyes(tokenId);
  }

  function randomIndex(
    uint256 tokenId,
    string memory keyPrefix,
    uint256 sourceArrayLength
  )
    internal
    pure
    returns (uint256 output)
  {
    uint256 rand = uint256(
      keccak256(
        abi.encodePacked(
          string(abi.encodePacked(
            keyPrefix,
            Strings.toString(tokenId)
          ))
        )
      )
    );
    uint256 seed = (((tokenId + 1) * 73129) + 95121) / 100000;
    output = ((rand / bytes(keyPrefix).length / sourceArrayLength / seed) + tokenId) % sourceArrayLength;
  }

  function random(
    uint256 tokenId,
    string memory keyPrefix,
    string[] memory sourceArray
  )
    internal
    pure
    returns (string memory output)
  {
    uint256 randIndex = randomIndex(tokenId, keyPrefix, sourceArray.length);
    output = sourceArray[randIndex];
  }
}
