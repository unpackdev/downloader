// SPDX-License-Identifier: MIT

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import "./Strings.sol";

import "./IQueenTraits.sol";
import "./IQueenPalace.sol";
import "./QueenTraitsBase.sol";
import "./RoyalLibrary.sol";

contract QueenTraits is QueenTraitsBase, IQueenTraits {
  using Strings for uint256;
  using RoyalLibrary for string;

  RoyalLibrary.sTRAIT[] private traits;
  RoyalLibrary.sRARITY[] private rarities;
  //(traitId => (rarityId => art))
  mapping(uint256 => mapping(uint256 => RoyalLibrary.sART[])) private arts;
  mapping(uint256 => bytes[]) private portraitDescriptions;

  uint256[] private _rarityPool;

  /************************** vCONSTRUCTOR REGION *************************************************** */

  constructor(
    IQueenPalace _queenPalace,
    bytes[] memory commonDescriptions,
    bytes[] memory rareDescriptions,
    bytes[] memory superRareDescriptions
  ) {
    //set ERC165 pattern
    _registerInterface(type(IQueenTraits).interfaceId);

    queenPalace = _queenPalace;

    //TRAITS
    traits.push(
      RoyalLibrary.sTRAIT({id: 1, traitName: "BACKGROUND", enabled: 1})
    );

    traits.push(RoyalLibrary.sTRAIT({id: 2, traitName: "FACE", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 3, traitName: "OUTFIT", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 4, traitName: "HEAD", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 5, traitName: "JEWELRY", enabled: 1}));

    traits.push(RoyalLibrary.sTRAIT({id: 6, traitName: "FRAME", enabled: 1}));

    //RARITIES
    rarities.push(
      RoyalLibrary.sRARITY({id: 1, rarityName: "COMMON", percentage: 85})
    );

    rarities.push(
      RoyalLibrary.sRARITY({id: 2, rarityName: "RARE", percentage: 10})
    );

    rarities.push(
      RoyalLibrary.sRARITY({id: 3, rarityName: "SUPER-RARE", percentage: 5})
    );
    //build rarity pool
    buildRarityPool();
    //Portrait Description Common
    portraitDescriptions[0] = commonDescriptions;
    //Portrait Description Rare
    portraitDescriptions[1] = rareDescriptions;
    //Portrait Description Super-Rare and Legendary
    portraitDescriptions[2] = superRareDescriptions;
  }

  /**
   *build rarity pool for lottery on mint
   */
  function buildRarityPool() private {
    //build rarity pool
    _rarityPool = new uint256[](100);
    uint256 poolIdx;
    uint256 percentageSum;

    for (uint256 idx = 0; idx < rarities.length; idx++) {
      percentageSum += rarities[idx].percentage;
    }

    for (uint256 idx = 0; idx < rarities.length; idx++) {
      for (
        uint256 counter = 1;
        counter <=
        rarities[idx].percentage + (idx == 0 ? (100 - percentageSum) : 0);
        counter++
      ) {
        _rarityPool[poolIdx++] = rarities[idx].id;
      }
    }
  }

  function rarityPool() external view override returns (uint256[] memory) {
    return _rarityPool;
  }

  /************************** ^CONSTRUCTOR REGION *************************************************** */

  /************************** vRARITY REGION ******************************************************** */

  /**
   *IN
   *_rarityId: Id of Rarity you want to consult
   *OUT
   *rarity: Rarity object found for given id
   */
  function getRarityById(uint256 _rarityId)
    public
    view
    override
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (rarities[idx].id == _rarityId) return rarities[idx];
    }

    return RoyalLibrary.sRARITY({id: 0, rarityName: "", percentage: 0});
  }

  /**
   *IN
   *_rarityName: Name of Rarity you want to consult
   *OUT
   *rarity: Rarity object found for given name
   */
  function getRarityByName(string memory _rarityName)
    public
    view
    override
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (
        keccak256(abi.encodePacked(rarities[idx].rarityName)) ==
        keccak256(abi.encodePacked(_rarityName))
      ) return rarities[idx];
    }

    return RoyalLibrary.sRARITY({id: 0, rarityName: "", percentage: 0});
  }

  /**
   *IN
   *_onlyWithArt: If should return only rarities with art in given traitId (obligatory to send valid tratId if this parameter is true. Send 0 otherwise)
   *_traitId: id of the trait to check if there is any art (obligatory to send valid tratId if _onlyWithArt is true. Send 0 otherwise)
   *OUT
   *rarities: Array with all rarities
   */
  function getRarities(bool _onlyWithArt, uint256 _traitId)
    public
    view
    override
    returns (RoyalLibrary.sRARITY[] memory raritiesList)
  {
    if (_onlyWithArt && _traitId <= 0)
      require(
        !_onlyWithArt || (_onlyWithArt && _traitId > 0),
        "Invalid Parameters!"
      );

    uint256 qtty = rarities.length;
    if (_onlyWithArt) {
      qtty = 0;
      for (uint256 idx = 0; idx < rarities.length; idx++) {
        if (arts[_traitId][rarities[idx].id].length > 0) qtty++;
      }
    }

    RoyalLibrary.sRARITY[]
      memory _availableRarities = new RoyalLibrary.sRARITY[](qtty);

    uint256 newIndex = 0;
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (_onlyWithArt) {
        if (arts[_traitId][rarities[idx].id].length > 0)
          _availableRarities[newIndex++] = rarities[idx];
      } else _availableRarities[newIndex++] = rarities[idx];
    }

    return _availableRarities;
  }

  /**
   *IN
   *_rarityId: Id of the rarity
   *OUT
   *rarityIdx: idx of rarity found in array
   */
  function getRarityIdxById(uint256 _rarityId)
    private
    view
    returns (uint256 rarityIdx)
  {
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      if (rarities[idx].id == _rarityId) {
        return idx;
      }
    }

    return 0;
  }

  /**
   *IN
   *_rarityName: Name of Rarity you want to consult
   *OUT
   *rarity: Rarity object updated
   */
  function setRarity(string memory _rarityName, uint256 _percentage)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    if (getRarityByName(_rarityName).id != 0)
      return getRarityByName(_rarityName);

    uint256 percSum = _percentage;
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      percSum += rarities[idx].percentage;
    }

    require(percSum <= 100, "Percentage Overflow");
    rarities.push(
      rarity = RoyalLibrary.sRARITY({
        id: rarities.length + 1,
        rarityName: _rarityName,
        percentage: _percentage
      })
    );

    buildRarityPool();
    emit RarityCreated(rarities.length, _rarityName, _percentage);
  }

  /**
   *IN
   *_rarityId: Id of Rarity you want to change the name
   *_percentage: if above 0, updates percentage. if not, dont
   *OUT
   *rarity: Rarity object updated
   */
  function updateRarity(
    uint256 _rarityId,
    uint256 _newPercentage,
    string memory _rarityNewName
  )
    external
    whenNotPaused
    onlyOwnerOrChiefDeveloperOrDAO
    onlyOnImplementationOrDAO
    returns (RoyalLibrary.sRARITY memory rarity)
  {
    if (getRarityById(_rarityId).id <= 0)
      return RoyalLibrary.sRARITY({id: 0, rarityName: "", percentage: 0});

    rarities[getRarityIdxById(_rarityId)].rarityName = keccak256(
      abi.encodePacked(_rarityNewName)
    ) != keccak256(abi.encodePacked(""))
      ? _rarityNewName
      : rarities[getRarityIdxById(_rarityId)].rarityName;
    rarities[getRarityIdxById(_rarityId)].percentage = _newPercentage > 0
      ? _newPercentage
      : rarities[getRarityIdxById(_rarityId)].percentage;

    uint256 percSum;
    for (uint256 idx = 0; idx < rarities.length; idx++) {
      percSum += rarities[idx].percentage;
    }
    require(percSum <= 100, "Percentage Overflow");

    buildRarityPool();

    emit RarityUpdated(
      rarities[getRarityIdxById(_rarityId)].id,
      rarities[getRarityIdxById(_rarityId)].rarityName,
      rarities[getRarityIdxById(_rarityId)].percentage
    );

    return rarities[getRarityIdxById(_rarityId)];
  }

  /************************** ^RARITY REGION ******************************************************** */

  /************************** DESCRIPTION REGION **************************************************** */

  /**
   *IN
   *_rarityId: Id of Rarity of QueenE
   *_index: Index of the phrase that we want to retrieve
   *OUT
   *description in given index
   */
  function getDescriptionByIdx(uint256 _rarityId, uint256 _index)
    public
    view
    override
    returns (bytes memory description)
  {
    if (_rarityId <= 1) return portraitDescriptions[_rarityId][_index];
    else return portraitDescriptions[2][_index];
  }

  /**
   *IN
   *_rarityId: rarity to count descriptions for
   *OUT
   *count: count of the descriptions
   */
  function getDescriptionsCount(uint256 _rarityId)
    public
    view
    override
    returns (uint256)
  {
    if (_rarityId <= 1) return portraitDescriptions[_rarityId].length;
    else return portraitDescriptions[2].length;
  }

  /**
   *IN
   *_rarityName: Name of Rarity you want to consult
   *OUT
   *rarity: Rarity object updated
   */
  function setDescription(uint256 _rarityId, bytes memory _description)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    bool alreadyExists = false;

    for (uint256 idx = 0; idx < portraitDescriptions[_rarityId].length; idx++) {
      bytes memory storedDesc = portraitDescriptions[_rarityId][idx];
      if (
        keccak256(abi.encodePacked(storedDesc)) ==
        keccak256(abi.encodePacked(_description))
      ) alreadyExists = true;
      break;
    }

    require(!alreadyExists, "QueenTraits::Descrption already exists");

    portraitDescriptions[_rarityId].push(_description);
  }

  /************************** ^DESCRIPTION REGION *************************************************** */

  /************************** vTRAITS REGION ******************************************************** */

  /**
   *IN
   *_idx: index of trait on array
   *OUT
   *trait: trait found in array
   */
  function getTrait(uint256 _id)
    public
    view
    override
    returns (RoyalLibrary.sTRAIT memory trait)
  {
    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (traits[idx].id == _id) return traits[idx];
    }
  }

  /**
   *IN
   *_traitName: name of the trait
   *OUT
   *trait: trait found in array
   */
  function getTraitByName(string memory _traitName)
    public
    view
    override
    returns (RoyalLibrary.sTRAIT memory trait)
  {
    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (
        keccak256(abi.encodePacked(traits[idx].traitName)) ==
        keccak256(abi.encodePacked(_traitName))
      ) return traits[idx];
    }
  }

  /**
   *IN
   *_traitName: name of the trait
   *OUT
   *traitIdx: idx of trait found in array
   */
  function getTraitIdxByName(string memory _traitName)
    private
    view
    returns (uint256 traitIdx)
  {
    require(
      keccak256(abi.encodePacked(_traitName)) !=
        keccak256(abi.encodePacked("")),
      "Name must have value!"
    );

    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (
        keccak256(abi.encodePacked(traits[idx].traitName)) ==
        keccak256(abi.encodePacked(_traitName))
      ) return idx;
    }
  }

  /**
   *IN
   *OUT
   *traits: all traits written in contract
   */
  function getTraits(bool _onlyEnabled)
    public
    view
    override
    returns (RoyalLibrary.sTRAIT[] memory _traits)
  {
    uint256 itens = 0;

    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (!_onlyEnabled) itens++;
      else if (traits[idx].enabled == 1) itens++;
    }

    RoyalLibrary.sTRAIT[] memory enabledTraits = new RoyalLibrary.sTRAIT[](
      itens
    );
    uint256 newIdx = 0;
    for (uint256 idx = 0; idx < traits.length; idx++) {
      if (!_onlyEnabled) enabledTraits[newIdx++] = traits[idx];
      else {
        if (traits[idx].enabled == 1) enabledTraits[newIdx++] = traits[idx];
      }
    }

    return enabledTraits;
  }

  /**
   *IN
   * _traitName: Name of the trait
   * _enabled: If trait is enabled. 0 is disabled, 1 is enabled
   *OUT
   *trait: final trait object in store
   */
  function setTrait(string memory _traitName, uint8 _enabled)
    public
    whenNotPaused
    onlyOwnerOrArtistOrDAO
    onlyOnImplementationOrDAO
  {
    require(_enabled >= 0 && _enabled <= 1, "Enabled value invalid");

    if (getTraitByName(_traitName).id > 0) //already exists
    {
      traits[getTraitIdxByName(_traitName)].enabled = _enabled;
      if (_enabled == 0)
        emit TraitDisabled(
          traits[getTraitIdxByName(_traitName)].id,
          traits[getTraitIdxByName(_traitName)].traitName
        );
      else
        emit TraitEnabled(
          traits[getTraitIdxByName(_traitName)].id,
          traits[getTraitIdxByName(_traitName)].traitName
        );
    } else {
      traits.push(
        RoyalLibrary.sTRAIT({
          id: traits.length,
          traitName: _traitName,
          enabled: _enabled
        })
      );
      emit TraitCreated(traits.length, _traitName, _enabled);
    }
  }

  /************************** ^TRAITS REGION ******************************************************** */

  /************************** vART REGION ******************************************************** */

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *_artUri: Uri of art that want to be checked
   *OUT
   *exists: true if uri already exists in the contract, false if not
   */
  function checkIfArtAlreadyExists(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) private view returns (bool exists, uint256 index) {
    //retrieve arts array
    if (arts[_traitId][_rarityId].length > 0) {
      RoyalLibrary.sART[] memory _arts = arts[_traitId][_rarityId];
      for (uint256 idx = 0; idx < _arts.length; idx++) {
        if (
          keccak256(abi.encodePacked(_arts[idx].uri)) ==
          keccak256(abi.encodePacked(_artUri))
        ) return (true, idx);
      }
    }

    return (false, 0);
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *_artUri: Uri of art that want to be checked
   *OUT
   *art: art found with uri
   */
  function getArtByUri(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) external view override returns (RoyalLibrary.sART memory art) {
    //retrieve arts array
    if (arts[_traitId][_rarityId].length > 0) {
      RoyalLibrary.sART[] memory _arts = arts[_traitId][_rarityId];
      for (uint256 idx = 0; idx < _arts.length; idx++) {
        if (
          keccak256(abi.encodePacked(_arts[idx].uri)) ==
          keccak256(abi.encodePacked(_artUri))
        ) return _arts[idx];
      }
    }
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *OUT
   *quantity: quantity of arts found for trait and rarity
   */
  function getArtCount(uint256 _traitId, uint256 _rarityId)
    external
    view
    override
    returns (uint256)
  {
    if (_rarityId > 0) {
      return arts[_traitId][_rarityId].length;
    } else {
      uint256 qtty;

      for (uint256 idx = 0; idx < rarities.length; idx++) {
        qtty += arts[_traitId][rarities[idx].id].length;
      }

      return qtty;
    }
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarityId: rarity Id of the art
   *_artIdx: index of art in array
   *OUT
   *art: sART object for given inputs
   */
  function getArt(
    uint256 _traitId,
    uint256 _rarityId,
    uint256 _artIdx
  ) external view override returns (RoyalLibrary.sART memory art) {
    require(
      arts[_traitId][_rarityId].length >= (_artIdx + 1),
      "No Art at given index"
    );

    return arts[_traitId][_rarityId][_artIdx];
  }

  /**
   *IN
   *_traitId: Id of the trait
   *_rarity: rarity of the art
   *OUT
   *arts: list of sART objects for given trait:rarity
   */
  function getArts(uint256 _traitId, uint256 _rarityId)
    external
    view
    override
    returns (RoyalLibrary.sART[] memory artsList)
  {
    return arts[_traitId][_rarityId];
  }

  /**
   *IN
   * _traitId: Id of the trait
   * _rarityId: rarity Id of the trait
   * _artUri: Uri of art on IPFS
   *OUT
   * art: final art object in store
   */
  function setArt(RoyalLibrary.sART[] memory _artUri)
    external
    whenNotPaused
    onlyOwnerOrArtistOrDAO
    onlyOnImplementationOrDAO
  {
    require(_artUri.length > 0, "Uri must have value!");

    for (uint256 index = 0; index < _artUri.length; index++) {
      require(_artUri[index].traitId > 0, "Trait id invalid!");
      require(_artUri[index].rarityId > 0, "Rarity id invalid!");
      require(getTrait(_artUri[index].traitId).enabled == 1, "Trait disabled!");

      (bool exists, ) = checkIfArtAlreadyExists(
        _artUri[index].traitId,
        _artUri[index].rarityId,
        _artUri[index].uri
      );

      if (exists) {
        //just go to the next
        continue;
      }

      arts[_artUri[index].traitId][_artUri[index].rarityId].push(
        RoyalLibrary.sART({
          traitId: _artUri[index].traitId,
          rarityId: _artUri[index].rarityId,
          artName: _artUri[index].artName,
          uri: _artUri[index].uri
        })
      );

      emit ArtCreated(
        _artUri[index].traitId,
        _artUri[index].rarityId,
        _artUri[index].artName,
        _artUri[index].uri
      );
    }
  }

  /**
   *IN
   * _traitId: Id of the trait
   * _rarityId: rarity Id of the trait
   * _artUri: Uri of art on IPFS
   *OUT
   * art: final art object in store
   */
  function removeArt(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  )
    external
    whenNotPaused
    onlyOwnerOrChiefArtist
    onlyOnImplementation
    returns (bool result)
  {
    require(
      keccak256(abi.encodePacked(_artUri)) != keccak256(abi.encodePacked("")),
      "Uri must have value!"
    );

    (bool found, uint256 index) = checkIfArtAlreadyExists(
      _traitId,
      _rarityId,
      _artUri
    );

    require(found, "No art found for given data!");

    //rearrenge array
    for (
      uint256 idx = index;
      idx < (arts[_traitId][_rarityId].length - 1);
      idx++
    ) {
      arts[_traitId][_rarityId][idx] = arts[_traitId][_rarityId][idx + 1];
    }

    //delete last index
    delete arts[_traitId][_rarityId][arts[_traitId][_rarityId].length - 1];
    arts[_traitId][_rarityId].pop();

    emit ArtRemoved(_traitId, _rarityId, _artUri);

    return true;
  }

  /************************** ^ART REGION ******************************************************** */
}
