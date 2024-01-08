// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatBase.sol";

/// @notice Habitat Accounts, basic functionality for social features.
// Audit-1: ok
contract HabitatAccount is HabitatBase {
  event ClaimUsername(address indexed account, bytes32 indexed shortString);

  /// @dev State transition when a user claims a (short) username.
  /// Only one username can be claimed for `msgSender`.
  /// If `msgSender` already claimed a name, then it should be freed.
  function onClaimUsername (address msgSender, uint256 nonce, bytes32 shortString) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // checks if the `shortString` is already taken
    require(HabitatBase._getStorage(_NAME_TO_ADDRESS_KEY(shortString)) == 0, 'SET');

    {
      // free the old name, if any
      uint256 oldName = HabitatBase._getStorage(_ADDRESS_TO_NAME_KEY(msgSender));
      if (oldName != 0) {
        HabitatBase._setStorage(_NAME_TO_ADDRESS_KEY(bytes32(oldName)), bytes32(0));
      }
    }

    HabitatBase._setStorage(_NAME_TO_ADDRESS_KEY(shortString), msgSender);
    HabitatBase._setStorage(_ADDRESS_TO_NAME_KEY(msgSender), shortString);

    if (_shouldEmitEvents()) {
      emit ClaimUsername(msgSender, shortString);
    }
  }
}
