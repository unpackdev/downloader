// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./TransparentUpgradeableProxy.sol";

/// @title PausableProxy
/// @author Iulian Rotaru
/// @notice Extension of the TransparentUpgradeableProxy that adds pause functionalities
contract PausableProxy is TransparentUpgradeableProxy {
  //
  //                      _              _
  //   ___ ___  _ __  ___| |_ __ _ _ __ | |_ ___
  //  / __/ _ \| '_ \/ __| __/ _` | '_ \| __/ __|
  // | (_| (_) | | | \__ \ || (_| | | | | |_\__ \
  //  \___\___/|_| |_|___/\__\__,_|_| |_|\__|___/
  //

  bytes32 internal constant _PAUSED_SLOT = 0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450;

  //
  //  _       _                        _
  // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
  // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
  // | | | | | ||  __/ |  | | | | (_| | \__ \
  // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
  //

  function _beforeFallback() internal virtual override {
    // remove the check that prevents admins from using the fallback
  }

  //
  //            _                        _
  //   _____  _| |_ ___ _ __ _ __   __ _| |___
  //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
  // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
  //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
  //

  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}

  /// @dev Retrieves Paused state
  /// @return Paused state
  function isPaused() external view returns (bool) {
    return StorageSlot.getBooleanSlot(_PAUSED_SLOT).value;
  }

  /// @dev Pauses system
  function pause() external ifAdmin {
    StorageSlot.getBooleanSlot(_PAUSED_SLOT).value = true;
  }

  /// @dev Unpauses system
  function unpause() external ifAdmin {
    StorageSlot.getBooleanSlot(_PAUSED_SLOT).value = false;
  }
}
