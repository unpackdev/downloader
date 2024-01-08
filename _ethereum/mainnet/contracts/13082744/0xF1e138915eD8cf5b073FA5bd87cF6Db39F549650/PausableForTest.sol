// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./Pausable.sol";

contract PausableForTest is Pausable {
  constructor(address _governor) Governable(_governor) {}
}
