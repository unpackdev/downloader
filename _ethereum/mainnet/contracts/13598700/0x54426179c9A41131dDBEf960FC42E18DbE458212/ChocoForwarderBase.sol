// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./draft-EIP712Upgradeable.sol";
import "./MinimalForwarderUpgradeable.sol";

contract ChocoForwarderBase is EIP712Upgradeable, MinimalForwarderUpgradeable {
  function initialize(string memory name, string memory version) public initializer {
    __EIP712_init_unchained(name, version);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}
