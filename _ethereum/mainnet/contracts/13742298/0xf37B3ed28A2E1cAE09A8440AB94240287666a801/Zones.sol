// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./L2Lib.sol";
import "./FurLib.sol";
import "./FurProxy.sol";
import "./MetaData.sol";
import "./ZoneDefinition.sol";

/// @title Zones
/// @author LFG Gaming LLC
/// @notice Zone management (overrides) for Furballs
contract Zones is FurProxy {
  // Tightly packed last-reward data
  mapping(uint256 => FurLib.ZoneReward) public zoneRewards;

  // Zone Number => Zone
  mapping(uint32 => IZone) public zoneMap;

  constructor(address furballsAddress) FurProxy(furballsAddress) { }

  // -----------------------------------------------------------------------------------------------
  // Public
  // -----------------------------------------------------------------------------------------------

  /// @notice The new instant function for play + move
  function play(FurLib.SnackMove[] calldata snackMoves, uint32 zone) external {
    furballs.engine().snackAndMove(snackMoves, zone, msg.sender);
  }

  /// @notice Check if Timekeeper is enabled for a given tokenId
  /// @dev TK=enabled by defauld (mode == 0); other modes (?); bools are expensive to store thus modes
  function isTimekeeperEnabled(uint256 tokenId) external view returns(bool) {
    return zoneRewards[tokenId].mode != 1;
  }

  /// @notice Allow players to disable TK on their furballs
  function disableTimekeeper(uint256[] calldata tokenIds) external {
    bool isJob = _allowedJob(msg.sender);
    for (uint i=0; i<tokenIds.length; i++) {
      require(isJob || furballs.ownerOf(tokenIds[i]) == msg.sender, "OWN");
      require(zoneRewards[tokenIds[i]].mode == 0, "MODE");
      zoneRewards[tokenIds[i]].mode = 1;
      zoneRewards[tokenIds[i]].timestamp = uint64(block.timestamp);
    }
  }

  /// @notice Allow players to disable TK on their furballs
  /// @dev timestamp is not set because TK can read the furball last action,
  ///       so it preserves more data and reduces gas to not keep track!
  function enableTimekeeper(uint256[] calldata tokenIds) external {
    bool isJob = _allowedJob(msg.sender);
    for (uint i=0; i<tokenIds.length; i++) {
      require(isJob || furballs.ownerOf(tokenIds[i]) == msg.sender, "OWN");
      require(zoneRewards[tokenIds[i]].mode != 0, "MODE");
      zoneRewards[tokenIds[i]].mode = 0;
    }
  }

  /// @notice Get the full reward struct
  function getZoneReward(uint256 tokenId) external view returns(FurLib.ZoneReward memory) {
    return zoneRewards[tokenId];
  }

  /// @notice Pre-computed rarity for Furballs
  function getFurballZoneReward(uint32 furballNum) external view returns(FurLib.ZoneReward memory) {
    return zoneRewards[furballs.tokenByIndex(furballNum - 1)];
  }

  /// @notice Get contract address for a zone definition
  function getZoneAddress(uint32 zoneNum) external view returns(address) {
    return address(zoneMap[zoneNum]);
  }

  /// @notice Public display (OpenSea, etc.)
  function getName(uint32 zoneNum) public view returns(string memory) {
    return _zoneName(zoneNum);
  }

  /// @notice Zones can have unique background SVGs
  function render(uint256 tokenId) external view returns(string memory) {
    uint zoneNum = zoneRewards[tokenId].zoneOffset;
    if (zoneNum == 0) return "";

    IZone zone = zoneMap[uint32(zoneNum - 1)];
    return address(zone) == address(0) ? "" : zone.background();
  }

  /// @notice OpenSea metadata
  function attributesMetadata(
    FurLib.FurballStats calldata stats, uint256 tokenId, uint32 maxExperience
  ) external view returns(bytes memory) {
    FurLib.Furball memory furball = stats.definition;
    uint level = furball.level;

    uint32 zoneNum = L2Lib.getZoneId(zoneRewards[tokenId].zoneOffset, furball.zone);

    if (zoneNum < 0x10000) {
      // When in explore, we check if TK has accrued more experience for this furball
      FurLib.ZoneReward memory last = zoneRewards[tokenId];
      if (last.timestamp > furball.last) {
        level = FurLib.expToLevel(furball.experience + zoneRewards[tokenId].experience, maxExperience);
      }
    }

    return abi.encodePacked(
      MetaData.traitValue("Level", level),
      MetaData.trait("Zone", _zoneName(zoneNum))
    );
  }

  // -----------------------------------------------------------------------------------------------
  // GameAdmin
  // -----------------------------------------------------------------------------------------------

  /// @notice Pre-compute some stats
  function computeStats(uint32 furballNum, uint16 baseRarity) external gameAdmin {
    _computeStats(furballNum, baseRarity);
  }

  /// @notice Update the timestamps on Furballs
  function timestampModes(
    uint256[] calldata tokenIds, uint64[] calldata lastTimestamps, uint8[] calldata modes
  ) external gameAdmin {
    for (uint i=0; i<tokenIds.length; i++) {
      zoneRewards[tokenIds[i]].timestamp = lastTimestamps[i];
      zoneRewards[tokenIds[i]].mode = modes[i];
    }
  }

  /// @notice Update the modes
  function setModes(
    uint256[] calldata tokenIds, uint8[] calldata modes
  ) external gameAdmin {
    for (uint i=0; i<tokenIds.length; i++) {
      zoneRewards[tokenIds[i]].mode = modes[i];
    }
  }

  /// @notice Update the timestamps on Furballs
  function setTimestamps(
    uint256[] calldata tokenIds, uint64[] calldata lastTimestamps
  ) external gameAdmin {
    for (uint i=0; i<tokenIds.length; i++) {
      zoneRewards[tokenIds[i]].timestamp = lastTimestamps[i];
    }
  }

  /// @notice When a furball earns FUR via Timekeeper
  function addFur(uint256 tokenId, uint32 fur) external gameAdmin {
    zoneRewards[tokenId].timestamp = uint64(block.timestamp);
    zoneRewards[tokenId].fur += fur;
  }

  /// @notice When a furball earns EXP via Timekeeper
  function addExp(uint256 tokenId, uint32 exp) external gameAdmin {
    zoneRewards[tokenId].timestamp = uint64(block.timestamp);
    zoneRewards[tokenId].experience += exp;
  }

  /// @notice Bulk EXP option for efficiency
  function addExps(uint256[] calldata tokenIds, uint32[] calldata exps) external gameAdmin {
    for (uint i=0; i<tokenIds.length; i++) {
      zoneRewards[tokenIds[i]].timestamp = uint64(block.timestamp);
      zoneRewards[tokenIds[i]].experience = exps[i];
    }
  }

  /// @notice Define the attributes of a zone
  function defineZone(address zoneAddr) external gameAdmin {
    IZone zone = IZone(zoneAddr);
    zoneMap[uint32(zone.number())] = zone;
  }

  /// @notice Hook for zone change
  function enterZone(uint256 tokenId, uint32 zone) external gameAdmin {
    _enterZone(tokenId, zone);
  }

  /// @notice Allow TK to override a zone
  function overrideZone(uint256[] calldata tokenIds, uint32 zone) external gameAdmin {
    for (uint i=0; i<tokenIds.length; i++) {
      _enterZone(tokenIds[i], zone);
    }
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  function _computeStats(uint32 furballNum, uint16 rarity) internal {
    uint256 tokenId = furballs.tokenByIndex(furballNum - 1);
    if (uint8(tokenId) == 0) {
      if (FurLib.extractBytes(tokenId, 5, 1) == 6) rarity += 10; // Furdenza body
      if (FurLib.extractBytes(tokenId, 11, 1) == 12) rarity += 10; // Furdenza hoodie
    }
    zoneRewards[tokenId].rarity = rarity;
  }

  /// @notice When a furball changes zone, we need to clear the zoneRewards timestamp
  function _enterZone(uint256 tokenId, uint32 zoneNum) internal {
    if (zoneRewards[tokenId].timestamp != 0) {
      zoneRewards[tokenId].timestamp = 0;
      zoneRewards[tokenId].experience = 0;
      zoneRewards[tokenId].fur = 0;
    }
    zoneRewards[tokenId].zoneOffset = (zoneNum + 1);

    if (zoneNum == 0 || zoneNum == 0x10000) return;

    // Additional requirement logic may occur in the zone
    IZone zone = zoneMap[zoneNum];
    if (address(zone) != address(0)) zone.enterZone(tokenId);
  }

  /// @notice Public display (OpenSea, etc.)
  function _zoneName(uint32 zoneNum) internal view returns(string memory) {
    if (zoneNum == 0) return "Explore";
    if (zoneNum == 0x10000) return "Battle";

    IZone zone = zoneMap[zoneNum];
    return address(zone) == address(0) ? "?" : zone.name();
  }

  function _allowedJob(address sender) internal view returns(bool) {
    return sender == furballs.engine().l2Proxy() ||
      _permissionCheck(sender) >= FurLib.PERMISSION_ADMIN;
  }
}
