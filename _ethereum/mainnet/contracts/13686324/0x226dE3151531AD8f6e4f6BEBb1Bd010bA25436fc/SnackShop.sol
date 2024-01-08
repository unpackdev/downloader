// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FurLib.sol";
import "./FurProxy.sol";
// import "./console.sol";

/// @title SnackShop
/// @author LFG Gaming LLC
/// @notice Simple data-storage for snacks
contract SnackShop is FurProxy {
  // snackId to "definition" of the snack
  mapping(uint32 => FurLib.Snack) private snack;

  // List of actual snack IDs
  uint32[] private snackIds;

  // tokenId => snackId => (snackId) + (stackSize)
  mapping(uint256 => mapping(uint32 => uint96)) private snackStates;

  // Internal cache for speed.
  uint256 private _intervalDuration;

  constructor(address furballsAddress) FurProxy(furballsAddress) {
    _intervalDuration = furballs.intervalDuration();
    _defineSnack(0x100, 24    ,  250, 15, 0);
    _defineSnack(0x200, 24 * 3,  750, 20, 0);
    _defineSnack(0x300, 24 * 7, 1500, 25, 0);
  }

  // -----------------------------------------------------------------------------------------------
  // Public
  // -----------------------------------------------------------------------------------------------

  /// @notice Returns the snacks currently applied to a Furball
  function snacks(uint256 tokenId) external view returns(FurLib.Snack[] memory) {
    // First, count how many active snacks there are...
    uint snackCount = 0;
    for (uint i=0; i<snackIds.length; i++) {
      uint256 remaining = _snackTimeRemaning(tokenId, snackIds[i]);
      if (remaining != 0) {
        snackCount++;
      }
    }

    // Next, build the return array...
    FurLib.Snack[] memory ret = new FurLib.Snack[](snackCount);
    if (snackCount == 0) return ret;

    uint snackIdx = 0;
    for (uint i=0; i<snackIds.length; i++) {
      uint256 remaining = _snackTimeRemaning(tokenId, snackIds[i]);
      if (remaining != 0) {
        uint96 snackState = snackStates[tokenId][snackIds[i]];
        ret[snackIdx] = snack[snackIds[i]];
        ret[snackIdx].fed = uint64(snackState >> 16);
        ret[snackIdx].count = uint16(snackState);
        snackIdx++;
      }
    }

    return ret;
  }

  /// @notice The public accessor calculates the snack boosts
  function snackEffects(uint256 tokenId) external view returns(uint256) {
    uint hap = 0;
    uint en = 0;
    for (uint i=0; i<snackIds.length; i++) {
      uint256 remaining = _snackTimeRemaning(tokenId, snackIds[i]);
      if (remaining != 0) {
        hap += snack[snackIds[i]].happiness;
        en += snack[snackIds[i]].energy;
      }
    }
    return (hap << 16) + (en);
  }

  /// @notice Public accessor for enumeration
  function getSnackIds() external view returns(uint32[] memory) {
    return snackIds;
  }

  /// @notice Load a snack by ID
  function getSnack(uint32 snackId) external view returns(FurLib.Snack memory) {
    return snack[snackId];
  }

  // -----------------------------------------------------------------------------------------------
  // GameAdmin
  // -----------------------------------------------------------------------------------------------

  /// @notice Allows admins to configure the snack store.
  function setSnack(
    uint32 snackId, uint32 duration, uint16 furCost, uint16 hap, uint16 en
  ) external gameAdmin {
    _defineSnack(snackId, duration, furCost, hap, en);
  }

  /// @notice Shortcut for admins/timekeeper
  function giveSnack(
    uint256 tokenId, uint32 snackId, uint16 count
  ) external gameAdmin {
    _assignSnack(tokenId, snackId, count);
  }

  /// @notice Shortcut for admins/timekeeper
  function giveSnacks(
    uint256 tokenId, uint64[] calldata snackStacks
  ) external gameAdmin {
    for (uint i=0; i<snackStacks.length; i++) {
      _assignSnack(tokenId, uint32(snackStacks[i] >> 16), uint16(snackStacks[i]));
    }
  }

  /// @notice Shortcut for admins/timekeeper
  function giveManySnacks(
    uint256[] calldata tokenIds, uint64[] calldata snackStacks
  ) external gameAdmin {
    for (uint i=0; i<snackStacks.length; i++) {
      _assignSnack(tokenIds[i], uint32(snackStacks[i] >> 16), uint16(snackStacks[i]));
    }
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  /// @notice Update the snackStates
  function _assignSnack(uint256 tokenId, uint32 snackId, uint16 count) internal {
    uint timeRemaining = _snackTimeRemaning(tokenId, snackId);
    if (timeRemaining == 0) {
      snackStates[tokenId][snackId] = uint96((block.timestamp << 16) + count);
    } else {
      snackStates[tokenId][snackId] = snackStates[tokenId][snackId] + count;
    }
  }

  /// @notice Both removes inactive _snacks from a token and searches for a specific snack Id index
  /// @dev Both at once saves some size & ensures that the _snacks are frequently cleaned.
  /// @return The index+1 of the existing snack
  // function _cleanSnack(uint256 tokenId, uint32 snackId) internal returns(uint256) {
  //   uint32 ret = 0;
  //   uint16 hap = 0;
  //   uint16 en = 0;
  //   for (uint32 i=1; i<=_snacks[tokenId].length && i <= FurLib.Max32; i++) {
  //     FurLib.Snack memory snack = _snacks[tokenId][i-1];
  //     // Has the snack transitioned from active to inactive?
  //     if (_snackTimeRemaning(snack) == 0) {
  //       if (_snacks[tokenId].length > 1) {
  //         _snacks[tokenId][i-1] = _snacks[tokenId][_snacks[tokenId].length - 1];
  //       }
  //       _snacks[tokenId].pop();
  //       i--; // Repeat this idx
  //       continue;
  //     }
  //     hap += snack.happiness;
  //     en += snack.energy;
  //     if (snackId != 0 && snack.snackId == snackId) {
  //       ret = i;
  //     }
  //   }
  //   return (ret << 32) + (hap << 16) + (en);
  // }

  /// @notice Check if the snack is active; returns 0 if inactive, otherwise the duration
  function _snackTimeRemaning(uint256 tokenId, uint32 snackId) internal view returns(uint256) {
    uint96 snackState = snackStates[tokenId][snackId];
    uint64 fed = uint64(snackState >> 16);
    if (fed == 0) return 0;

    uint16 count = uint16(snackState);
    uint32 duration = snack[snackId].duration;
    uint256 expiresAt = uint256(fed + (count * duration * _intervalDuration));
    return expiresAt <= block.timestamp ? 0 : (expiresAt - block.timestamp);
  }

  /// @notice Store a new snack definition
  function _defineSnack(
    uint32 snackId, uint32 duration, uint16 furCost, uint16 hap, uint16 en
  ) internal {
    if (snack[snackId].snackId != snackId) {
      snackIds.push(snackId);
    }

    snack[snackId].snackId = snackId;
    snack[snackId].duration = duration;
    snack[snackId].furCost = furCost;
    snack[snackId].happiness = hap;
    snack[snackId].energy = en;
    snack[snackId].count = 1;
    snack[snackId].fed = 0;
  }
}
