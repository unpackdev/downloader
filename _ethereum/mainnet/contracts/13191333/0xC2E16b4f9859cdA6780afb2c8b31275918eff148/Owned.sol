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
// O1 => Caller is not admin

/// @title Owned
/// @author Iulian Rotaru
/// @notice Owner logics, reading storage slot to retrieve admin
contract Owned {
  //
  //                      _              _
  //   ___ ___  _ __  ___| |_ __ _ _ __ | |_ ___
  //  / __/ _ \| '_ \/ __| __/ _` | '_ \| __/ __|
  // | (_| (_) | | | \__ \ || (_| | | | | |_\__ \
  //  \___\___/|_| |_|___/\__\__,_|_| |_|\__|___/
  //

  // Storage slot for the Admin address
  bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  //
  //                      _ _  __ _
  //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
  // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
  // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
  // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
  //

  // Modifier allowing only admins to call methods
  modifier isAdmin() {
    require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender, 'O1');
    _;
  }

  //
  //            _                        _
  //   _____  _| |_ ___ _ __ _ __   __ _| |___
  //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
  // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
  //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
  //

  /// @dev Retrieves Admin address
  /// @return Admin address
  function getAdmin() public view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }
}
