// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IAccessControl.sol";
import "./Strings.sol";

contract UseAccessControl {
  IAccessControl public accessControl;

  constructor(address _accessControl) {
    accessControl = IAccessControl(_accessControl);
  }

  modifier onlyRole(bytes32 role) {
      _checkRole(role, msg.sender);
      _;
  }

  function _checkRole(bytes32 role, address account) internal view {
    if (!accessControl.hasRole(role, account)) {
        revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(account), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
    }
  }
}