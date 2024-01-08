// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./Initializable.sol";

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// V1 => Already initializing
// V2 => Invalid version received. Expected current

/// @title Versioned
/// @author Iulian Rotaru
/// @notice Initialized for multiple versions
contract Versioned {
  //
  //      _        _
  //  ___| |_ __ _| |_ ___
  // / __| __/ _` | __/ _ \
  // \__ \ || (_| | ||  __/
  // |___/\__\__,_|\__\___|
  //

  // Stores the current implementation version
  uint256 version;

  // Stores the initializing state for each version
  bool private _initializing;

  //
  //                      _ _  __ _
  //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
  // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
  // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
  // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
  //

  // Allows to be called only if version number is current version + 1
  modifier initVersion(uint256 _version) {
    require(!_initializing, 'V1');
    require(_version == version + 1, 'V2');
    version = _version;

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  //
  //            _                        _
  //   _____  _| |_ ___ _ __ _ __   __ _| |___
  //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
  // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
  //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
  //

  /// @dev Retrieves current implementation version
  /// @return Implementatiomn version
  function getVersion() public view returns (uint256) {
    return version;
  }
}
