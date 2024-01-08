// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./StorageSlot.sol";

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// P1 => Contract is not paused
// P2 => Contract is paused

/// @title Pausable
/// @author Iulian Rotaru
/// @notice Pausable logics, reading storage slot to retrieve pause state
contract Pausable {
  //
  //                      _              _
  //   ___ ___  _ __  ___| |_ __ _ _ __ | |_ ___
  //  / __/ _ \| '_ \/ __| __/ _` | '_ \| __/ __|
  // | (_| (_) | | | \__ \ || (_| | | | | |_\__ \
  //  \___\___/|_| |_|___/\__\__,_|_| |_|\__|___/
  //

  // Storage slot for the Paused state
  bytes32 internal constant _PAUSED_SLOT = 0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450;

  //
  //                      _ _  __ _
  //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
  // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
  // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
  // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
  //

  // Allows methods to be called if paused
  modifier whenPaused() {
    require(StorageSlot.getBooleanSlot(_PAUSED_SLOT).value == true, 'P1');
    _;
  }

  // Allows methods to be called if not paused
  modifier whenNotPaused() {
    require(StorageSlot.getBooleanSlot(_PAUSED_SLOT).value == false, 'P1');
    _;
  }
}
