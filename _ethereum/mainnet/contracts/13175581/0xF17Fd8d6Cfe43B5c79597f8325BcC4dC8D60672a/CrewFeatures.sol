// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./ICrewGenerator.sol";


/**
 * @dev Contract which generates crew features based on the set they're part of
 */
contract CrewFeatures is Ownable {

  // Mapping of collectionIds to contract addresses of generators
  mapping (uint => ICrewGenerator) private _generators;

  // Mapping of tokenIds to collection membership
  mapping (uint => uint) private _crewCollection;

  // Mapping of tokenIds to modifiers
  mapping (uint => uint) private _crewModifiers;

  // Mapping indicating allowed managers
  mapping (address => bool) private _managers;

  event CollectionCreated(uint indexed id);
  event CollectionSeeded(uint indexed id);

  // Modifier to check if calling contract has the correct minting role
  modifier onlyManagers {
    require(isManager(_msgSender()), "CrewFeatures: Only managers can call this function");
    _;
  }

  /**
   * @dev Defines a collection and points to the relevant contract
   * @param _collId Id for the collection
   * @param _generator Address of the contract adhering to the appropriate interface
   */
  function setGenerator(uint _collId, ICrewGenerator _generator) external onlyOwner {
    _generators[_collId] = _generator;
    emit CollectionCreated(_collId);
  }

  /**
   * @dev Sets the seed for a given collection
   * @param _collId Id for the collection
   * @param _seed The seed to bootstrap the generator with
   */
  function setGeneratorSeed(uint _collId, bytes32 _seed) external onlyManagers {
    require(address(_generators[_collId]) != address(0), "CrewFeatures: collection must be defined");
    ICrewGenerator generator = _generators[_collId];
    generator.setSeed(_seed);
    emit CollectionSeeded(_collId);
  }

  /**
   * @dev Set a token with a specific crew collection
   * @param _crewId The ERC721 tokenID for the crew member
   * @param _collId The set ID to assign the crew member to
   * @param _mod An optional modifier ranging from 0 (default) to 10,000
   */
  function setToken(uint _crewId, uint _collId, uint _mod) external onlyManagers {
    require(address(_generators[_collId]) != address(0), "CrewFeatures: collection must be defined");
    _crewCollection[_crewId] = _collId;

    if (_mod > 0) {
      _crewModifiers[_crewId] = _mod;
    }
  }

  /**
   * @dev Returns the generated features for a crew member as a bitpacked uint
   * @param _crewId The ERC721 tokenID for the crew member
   */
  function getFeatures(uint _crewId) public view returns (uint) {
    uint generatorId = _crewCollection[_crewId];
    ICrewGenerator generator = _generators[generatorId];
    uint features = generator.getFeatures(_crewId, _crewModifiers[_crewId]);
    features |= generatorId << 0;
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
