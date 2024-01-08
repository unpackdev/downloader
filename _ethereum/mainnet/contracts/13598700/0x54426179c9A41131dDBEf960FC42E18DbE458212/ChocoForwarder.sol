// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChocoForwarderBase.sol";

contract ChocoForwarder is ChocoForwarderBase {
  constructor(string memory name, string memory version) {
    initialize(name, version);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}
