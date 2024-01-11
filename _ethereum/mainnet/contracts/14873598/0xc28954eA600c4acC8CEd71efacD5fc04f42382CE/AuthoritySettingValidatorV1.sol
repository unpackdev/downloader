// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./SettingRulesConfigurable.sol";
import "./SettingsV1.sol";

// Oracle settings
//
// Pluggable contract which implements setting changes and can be evolved to new contracts
//
contract AuthoritySettingValidatorV1 is Ownable, SettingRulesConfigurable {
  // Constructor stub

  // -- don't accept raw ether
  receive() external payable {
    revert('unsupported');
  }

  // -- reject any other function
  fallback() external payable {
    revert('unsupported');
  }
}
