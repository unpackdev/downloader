// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

import "./AccessControl.sol";

///@title QuarantineList contract
///@notice Handle the logic for the quarantine list
abstract contract QuarantineList is AccessControl {
  /// -----------------------------
  ///         Storage
  /// -----------------------------
  uint256 public min_quarantine_duration = 1 days;
  mapping(address => uint128) public quarantineList;

  /// -----------------------------
  ///         Events
  /// -----------------------------

  event AddedToQuarantine(address asset, uint128 expirationTime);
  event RemovedFromQuarantine(address asset);
  /// -----------------------------
  ///         Errors
  /// -----------------------------

  error AssetIsQuarantined(address asset);
  error AssetIsNotQuarantined(address asset);
  error ShortenedExpiration(uint128 currentExpiration, uint128 expiration);
  error ShortQurantineDuration(uint128 duration);

  /// -----------------------------
  ///         Admin external
  /// -----------------------------

  ///@notice Set the minimum quarantine duration
  ///@param _min_quarantine_duration the new minimum quarantine duration
  function set_min_quarantine_duration(uint256 _min_quarantine_duration) external onlyOwner {
    min_quarantine_duration = _min_quarantine_duration;
  }

  ///@notice Add an asset to the quarantine list
  ///@param _asset the address of the assset to be added to the quarantine list
  ///@param _duration the time (in seconds) that the asset should stay in quarantine
  function addToQuarantine(address _asset, uint128 _duration) external onlyGuard {
    if (_duration < min_quarantine_duration) revert ShortQurantineDuration(_duration);

    // gas savings
    uint128 expiration = uint128(block.timestamp) + _duration;
    uint128 currentExpiration = quarantineList[_asset];

    // the new expiration cannot be before the curent one i.e. expiration cannot be reduced, just
    // extended
    if (expiration <= currentExpiration) revert ShortenedExpiration(currentExpiration, expiration);

    quarantineList[_asset] = expiration;

    emit AddedToQuarantine(_asset, expiration);
  }

  ///@notice Remove an asset from the quarantine list
  ///@param _asset the address of the assset to be removed from the quarantine list
  function removeFromQuarantine(address _asset) external onlyGuard {
    // If the asset has nto been quarantined or the duarion period has expired then revert
    if (quarantineList[_asset] < uint128(block.timestamp)) revert AssetIsNotQuarantined(_asset);

    // just set the duration to zero to remove from quarantine
    quarantineList[_asset] = 0;
    emit RemovedFromQuarantine(_asset);
  }

  /// -----------------------------
  ///    External view functions
  /// -----------------------------

  ///@notice Check if an asset is quarantined
  ///@param _asset the address of the assset to be checked
  function isQuarantined(address _asset) public view returns (bool) {
    return quarantineList[_asset] >= uint128(block.timestamp);
  }

  ///@notice Check if any asset from a given list is quarantined
  ///@param _assets an array of asset addresses that need to be checked
  ///@return address of first quarantined asset or address(0x0) if none quarantined
  function isAnyQuarantined(address[] memory _assets) public view returns (address) {
    for (uint256 i = 0; i < _assets.length;) {
      if (isQuarantined(_assets[i])) return _assets[i];

      unchecked {
        ++i;
      }
    }
    return address(0x0);
  }
}
