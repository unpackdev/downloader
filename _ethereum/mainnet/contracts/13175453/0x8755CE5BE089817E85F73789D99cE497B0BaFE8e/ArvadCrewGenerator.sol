// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Procedural.sol";


/**
 * @dev Base contract for generating Arvad Crew members
 */
contract ArvadCrewGenerator {
  using Procedural for bytes32;

  bytes32 public generatorSeed;

  /**
   * @dev Returns the seed for a given crew member ID
   * @param _crewId The ERC721 tokenId for the crew member
   */
  function getCrewSeed(uint _crewId) public view returns (bytes32) {
    return generatorSeed.derive(_crewId);
  }

  /**
   * @dev Generates sex of the crew member
   * 1 = Male, 2 = Female
   * @param _seed Generator seed to derive from
   */
  function generateSex(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("sex");
    return uint(seed.getIntBetween(1, 3));
  }

  /**
   * @dev Generates body based on sex
   * @param _seed Generator seed to derive from
   * 1 - 6 = Male bodies, 7 - 12 = Female bodies
   * @param _sex The sex of the crew member
   */
  function generateBody(bytes32 _seed, uint _sex) public pure returns (uint) {
    bytes32 seed = _seed.derive("body");
    return uint(seed.getIntBetween(1, 7)) + (_sex - 1) * 6;
  }

  /**
   * @dev Generates the class based on a pre-defined distribution
   * 1 = Pilot, 2 = Engineer, 3 = Miner, 4 = Merchant, 5 = Scientist
   * @param _seed Generator seed to derive from
   */
  function generateClass(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("class");
    uint roll = uint(seed.getIntBetween(1, 10001));
    uint[5] memory classes = [ uint(703), 2770, 7122, 8837, 10000 ];

    for (uint i = 0; i < 5; i++) {
      if (roll <= classes[i]) {
        return i + 1;
      }
    }

    return 1;
  }

  /**
   * @dev Generates the job on the Arvad boosting chances based on modifier
   * @param _seed Generator seed to derive from
   * @param _class The class of the crew member
   * @param _mod Rarity modifier
   */
  function generateArvadJob(bytes32 _seed, uint _class, uint _mod) public pure returns (uint) {
    bytes32 seed = _seed.derive("arvadJobRank");

    // Generate job "rank" first
    uint[4] memory ranks = [ uint(5333), 8000, 9333, 10000 ];
    uint roll = uint(seed.getIntBetween(int128(_mod), 10001));
    uint rank = 0;

    for (uint i = 0; i < 4; i++) {
      if (roll <= ranks[i]) {
        rank = i;
        break;
      }
    }

    // Generate job based on rank and class
    uint[13][5] memory jobs;

    if (rank == 3) {
      jobs = [
        [ uint(830), 1107, 1217, 1355, 3154, 3707, 6473, 6888, 7580, 8133, 8548, 8963, 10000 ],
        [ uint(0), 0, 0, 189, 189, 943, 3208, 7736, 10000, 10000, 10000, 10000, 10000 ],
        [ uint(0), 0, 0, 0, 741, 2222, 4444, 4444, 4444, 4444, 10000, 10000, 10000 ],
        [ uint(0), 0, 154, 154, 798, 4402, 4659, 4659, 4659, 4659, 6203, 9678, 10000 ],
        [ uint(0), 2143, 2857, 5000, 5000, 5000, 5000, 5357, 5714, 10000, 10000, 10000, 10000 ]
      ];
    } else if (rank == 2) {
      jobs = [
        [ uint(733), 978, 1076, 1320, 3276, 3765, 6210, 6577, 7555, 8044, 8411, 8778, 10000 ],
        [ uint(0), 870, 870, 1159, 1159, 1449, 4058, 7971, 10000, 10000, 10000, 10000, 10000 ],
        [ uint(0), 0, 0, 0, 1125, 3625, 4875, 4875, 4875, 5875, 8125, 9813, 10000 ],
        [ uint(368), 1068, 1419, 1594, 2119, 4921, 4921, 4921, 4921, 4921, 6760, 9387, 10000 ],
        [ uint(134), 1478, 2313, 4701, 4701, 4701, 5000, 5224, 5522, 10000, 10000, 10000, 10000 ]
      ];
    } else if (rank == 1) {
      jobs = [
        [ uint(682), 2500, 2500, 2955, 5682, 5682, 7500, 7500, 8864, 8864, 8864, 8864, 10000 ],
        [ uint(295), 999, 999, 1421, 1421, 1421, 3952, 7750, 10000, 10000, 10000, 10000, 10000 ],
        [ uint(0), 434, 503, 503, 1631, 4059, 5620, 5880, 5880, 7268, 9089, 9740, 10000 ],
        [ uint(203), 880, 1286, 1624, 1794, 3824, 3824, 3824, 3824, 5178, 6701, 9239, 10000 ],
        [ uint(258), 688, 1720, 4731, 4731, 4731, 4731, 4731, 4946, 8387, 8387, 10000, 10000 ]
      ];
    } else {
      jobs = [
        [ uint(541), 3243, 3243, 4144, 7748, 7748, 7748, 7748, 9550, 9550, 9550, 9550, 10000 ],
        [ uint(530), 1172, 1172, 1814, 1814, 1814, 2456, 6308, 9037, 10000, 10000, 10000, 10000 ],
        [ uint(0), 514, 582, 582, 1495, 3550, 5605, 5947, 5947, 7546, 8916, 9772, 10000 ],
        [ uint(443), 1076, 1667, 2300, 2300, 3143, 3143, 3143, 3143, 4409, 5675, 8840, 10000 ],
        [ uint(0), 556, 2778, 9444, 9444, 9444, 9444, 9444, 10000, 10000, 10000, 10000, 10000 ]
      ];
    }

    seed = _seed.derive("arvadJob");
    roll = uint(seed.getIntBetween(1, 10001));

    for (uint i = 0; i < 13; i++) {
      if (roll <= jobs[_class - 1][i]) {
        return rank * 13 + i + 1;
      }
    }

    return 1;
  }

  /**
   * @dev Generates clothes based on the sex and class
   * 1-3 = Light spacesuit, 4-6 = Heavy spacesuit, 7-9 = Lab coat, 10-12 = Industrial, 12-15 = Rebel, 16-18 = Station
   * @param _seed Generator seed to derive from
   * @param _class The class of the crew member
   */
  function generateClothes(bytes32 _seed, uint _class) public pure returns (uint) {
    bytes32 seed = _seed.derive("clothes");
    uint roll = uint(seed.getIntBetween(1, 10001));
    uint outfit = 0;

    uint[6][5] memory outfits = [
      [ uint(3333), 3333, 3333, 3333, 6666, 10000 ],
      [ uint(2500), 5000, 5000, 7500, 7500, 10000 ],
      [ uint(2500), 5000, 5000, 7500, 7500, 10000 ],
      [ uint(5000), 5000, 5000, 5000, 5000, 10000 ],
      [ uint(3333), 3333, 6666, 6666, 6666, 10000 ]
    ];

    for (uint i = 0; i < 6; i++) {
      if (roll <= outfits[_class - 1][i]) {
        outfit = i;
        break;
      }
    }

    seed = _seed.derive("clothesVariation");
    roll = uint(seed.getIntBetween(1, 4));
    return (outfit * 3) + roll;
  }

  /**
   * @dev Generates hair based on the sex
   * 0 = Bald, 1 - 5 = Male hair, 6 - 11 = Female hair
   * @param _seed Generator seed to derive from
   * @param _sex The sex of the crew member
   */
  function generateHair(bytes32 _seed, uint _sex) public pure returns (uint) {
    bytes32 seed = _seed.derive("hair");
    uint style;

    if (_sex == 1) {
      style = uint(seed.getIntBetween(0, 6));
    } else {
      style = uint(seed.getIntBetween(0, 7));
    }

    if (style == 0) {
      return 0;
    } else {
      return style + (_sex - 1) * 5;
    }
  }

  /**
   * @dev Generates facial hair, piercings, scars depending on sex
   * 0 = None, 1 = Scar, 2 = Piercings, 3 - 7 = Facial hair
   * @param _seed Generator seed to derive from
   * @param _sex The sex of the crew member
   */
  function generateFacialFeatures(bytes32 _seed, uint _sex) public pure returns (uint) {
    bytes32 seed = _seed.derive("facialFeatures");
    uint feature = uint(seed.getIntBetween(0, 3));

    if (_sex == 1 && feature == 2) {
      seed = _seed.derive("facialHair");
      return uint(seed.getIntBetween(3, 8));
    } else {
      return feature;
    }
  }

  /**
   * @dev Generates hair color applied to both hair and facial hair (if applicable)
   * @param _seed Generator seed to derive from
   */
  function generateHairColor(bytes32 _seed) public pure returns (uint) {
    bytes32 seed = _seed.derive("hairColor");
    return uint(seed.getIntBetween(1, 6));
  }

  /**
   * @dev Generates a potential head piece based on class
   * 0 = None, 1 = Goggles, 2 = Glasses, 3 = Patch, 4 = Mask, 5 = Helmet
   * @param _seed Generator seed to derive from
   * @param _mod Modifier that increases chances of more rare items
   */
  function generateHeadPiece(bytes32 _seed, uint _class, uint _mod) public pure returns (uint) {
    bytes32 seed = _seed.derive("headPiece");
    uint roll = uint(seed.getIntBetween(int128(_mod), 10001));
    uint[6][5] memory headPieces = [
      [ uint(6667), 6667, 8445, 8889, 9778, 10000 ],
      [ uint(6667), 7619, 9524, 9524, 9524, 10000 ],
      [ uint(6667), 8572, 8572, 9524, 9524, 10000 ],
      [ uint(6667), 6667, 7778, 7778, 10000, 10000 ],
      [ uint(6667), 6667, 8572, 9048, 10000, 10000 ]
    ];

    for (uint i = 0; i < 6; i++) {
      if (roll <= headPieces[_class - 1][i]) {
        return i;
      }
    }

    return 0;
  }
}
