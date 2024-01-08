// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FurLib.sol";
import "./FurProxy.sol";
import "./MetaData.sol";
import "./ZoneDefinition.sol";

/// @title Zones
/// @author LFG Gaming LLC
/// @notice Zone management (overrides) for Furballs
contract Zones is FurProxy {
  // Zone Number => Zone
  mapping(uint32 => IZone) public zoneMap;

  // Override of tokenId => zoneNum
  mapping(uint256 => uint32) private furballZones;

  // Internal tracker for a furball when gaining in the zone
  struct LastGain {
    uint32 total;
    uint32 experience;
    uint64 timestamp;
  }

  // Tightly packed EXP gain + timestamp
  mapping(uint256 => LastGain) public lastGain;

  constructor(address furballsAddress) FurProxy(furballsAddress) { }

  // -----------------------------------------------------------------------------------------------
  // Public
  // -----------------------------------------------------------------------------------------------

  /// @notice When a furball earns EXP via Timekeeper
  function addExp(uint256 tokenId, uint32 exp) external gameAdmin {
    lastGain[tokenId].timestamp = uint64(block.timestamp);
    lastGain[tokenId].experience = exp;
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
    uint zoneNum = furballZones[tokenId];
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
    uint32 zoneNum = furballZones[tokenId];
    if (zoneNum == 0) zoneNum = furball.zone;
    else zoneNum = zoneNum - 1;

    if (furball.zone < 0x10000) {
      // When in explore, we check if TK has accrued more experience for this furball
      LastGain memory last = lastGain[tokenId];
      if (last.timestamp > furball.last) {
        level = FurLib.expToLevel(furball.experience + lastGain[tokenId].experience, maxExperience);
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

  /// @notice Define the attributes of a zone
  function defineZone(
    address zoneAddr
  ) external gameAdmin {
    IZone zone = IZone(zoneAddr);
    zoneMap[uint32(zone.number())] = zone;
  }

  /// @notice Hook for zone change
  function enterZone(uint256 tokenId, uint32 zone) external gameAdmin returns (uint256) {
    _enterZone(tokenId, zone);
    return zone;
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

  /// @notice Caches ID/number as a byproduct
  /// @dev When a furball changes zone, we need to clear the lastGain timestamp
  function _enterZone(uint256 tokenId, uint32 zoneNum) internal {
    lastGain[tokenId].timestamp = 0;
    lastGain[tokenId].experience = 0;
    furballZones[tokenId] = (zoneNum + 1);
    // _cacheFurballNumber(tokenId);

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
}
