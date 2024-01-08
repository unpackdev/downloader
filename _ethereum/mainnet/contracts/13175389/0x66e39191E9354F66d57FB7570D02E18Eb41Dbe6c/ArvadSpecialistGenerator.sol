// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./ArvadCrewGenerator.sol";
import "./InfluenceSettings.sol";
import "./Procedural.sol";


/**
 * @dev Contract which generates crew features based on the set they're part of
 */
contract ArvadSpecialistGenerator is ArvadCrewGenerator {
  using Procedural for bytes32;

  constructor() {
    generatorSeed = InfluenceSettings.MASTER_SEED.derive("crew:1");
  }

  /**
   * @dev Returns the features for the specific crew member
   * @param _crewId The ERC721 tokenId for the crew member
   * @param _mod A modifier between 0 and 10,000
   */
  function getFeatures(uint _crewId, uint _mod) public view returns (uint) {
    require(generatorSeed != "", "ArvadSpecialistGenerator: seed not yet set");
    uint features = 0;
    uint mod = 2500 + _mod;
    bytes32 crewSeed = getCrewSeed(_crewId);
    uint sex = generateSex(crewSeed);
    features |= sex << 8; // 2 bytes
    features |= generateBody(crewSeed, sex) << 10; // 16 bytes
    uint class = generateClass(crewSeed);
    features |= class << 26; // 8 bytes
    features |= generateArvadJob(crewSeed, class, mod) << 34; // 16 bytes
    features |= generateClothes(crewSeed, class) << 50; // 16 bytes to account for color variation
    features |= generateHair(crewSeed, sex) << 66; // 16 bytes
    features |= generateFacialFeatures(crewSeed, sex) << 82; // 16 bytes
    features |= generateHairColor(crewSeed) << 98; // 8 bytes
    features |= generateHeadPiece(crewSeed, class, mod) << 106; // 8 bytes
    features |= generateItem(crewSeed) << 114; // 8 bytes
    return features;
  }

  /**
   * @dev Generates special features
   * 0 = None, 1 = Glow, 2 - 5 = Drone
   * @param _seed Generator seed to derive from
   */
  function generateItem(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("item");
    uint[6] memory items = [ uint(7500), 9200, 9400, 9600, 9800, 10000 ];
    uint roll = uint(seed.getIntBetween(1, 10001));

    for (uint i = 0; i < 6; i++) {
      if (roll <= items[i]) {
        return i;
      }
    }

    return 0;
  }
}
