// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./ArvadCrewGenerator.sol";
import "./InfluenceSettings.sol";
import "./Procedural.sol";


/**
 * @dev Contract which generates crew features based on the set they're part of
 */
contract ArvadCitizenGenerator is ArvadCrewGenerator, Ownable {
  using Procedural for bytes32;

  // Mapping indicating allowed managers
  mapping (address => bool) private _managers;

  // Modifier to check if calling contract has the correct minting role
  modifier onlyManagers {
    require(isManager(_msgSender()), "ArvadCitizenGenerator: Only managers can call this function");
    _;
  }

  /**
   * @dev Sets the initial seed to allow for feature generation
   * @param _seed Random seed
   */
  function setSeed(bytes32 _seed) external onlyManagers {
    require(generatorSeed == "", "ArvadCitizenGenerator: seed already set");
    generatorSeed = InfluenceSettings.MASTER_SEED.derive(uint(_seed));
  }

  /**
   * @dev Returns the features for the specific crew member
   * @param _crewId The ERC721 tokenId for the crew member
   * @param _mod A modifier between 0 and 10,000
   */
  function getFeatures(uint _crewId, uint _mod) public view returns (uint) {
    require(generatorSeed != "", "ArvadCitizenGenerator: seed not yet set");
    uint features = 0;
    uint mod = _mod;
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
    return features;
  }

  /**
   * @dev Add a new account / contract that can mint / burn crew members
   * @param _manager Address of the new manager
   */
  function addManager(address _manager) external onlyOwner {
    _managers[_manager] = true;
  }

  /**
   * @dev Remove a current manager
   * @param _manager Address of the manager to be removed
   */
  function removeManager(address _manager) external onlyOwner {
    _managers[_manager] = false;
  }

  /**
   * @dev Checks if an address is a manager
   * @param _manager Address of contract / account to check
   */
  function isManager(address _manager) public view returns (bool) {
    return _managers[_manager];
  }
}
