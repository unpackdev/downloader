//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


// On-chain reference for metadata rarity and other attributes 
// from the initial dice.
contract InitDiceAttributes {

  uint8 immutable public REGULAR = 0;
  uint8 immutable public ELITE = 1;
  uint8 immutable public SUPER_ELITE = 2;
  uint8 immutable public ULTRA_ELITE = 3;

  // no need for a mapping, we're just going by index
  uint8[3636] public rarities; // 0-3
  uint8[3636] public scores;   // 2-12

  constructor(uint8[3636] memory _rarities, uint8[3636] memory _scores)  {
    rarities = _rarities;
    scores = _scores;
  }

  function getRarity(uint diceId) public view returns (uint8 r) {
    return rarities[diceId];
  }

  function getScore(uint diceId) public view returns (uint8 r) {
    return scores[diceId];
  }

  // function addRarities(uint8[] memory _rarities) public {
  //   for (uint i=0; i < _rarities.length; i++) {
  //     rarities.push(_rarities[i]);
  //   }
  // }
  // function addScores(uint8[] memory _scores) public {
  //   for (uint i=0; i < _scores.length; i++) {
  //     scores.push(_scores[i]);
  //   }
  // }

}